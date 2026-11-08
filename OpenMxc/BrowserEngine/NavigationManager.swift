import AppKit
import SwiftUI
import WebKit

@Observable
@MainActor
final class NavigationManager: NSObject {
    private(set) var webView: WKWebView
    private(set) var currentURL: URL?
    private(set) var pageTitle = ""
    private(set) var isLoading = false
    private(set) var estimatedProgress: Double = 0
    private(set) var canGoBack = false
    private(set) var canGoForward = false
    private(set) var hasCommittedNavigation = false
    private(set) var loadError: String?
    private(set) var webContentCrashed = false
    /// Dominant page color used to subtly tint the chrome accent; nil for
    /// neutral pages or before the first sample completes.
    private(set) var dominantColor: Color?

    private(set) var lastLoadedURL: URL?
    var isPrivateBrowsing = false
    private var observations: [NSKeyValueObservation] = []
    private var pendingMainFrameNavigation = false
    private var pendingDownloadURL: URL?
    private var activeDownload: WKDownload?
    private var activeDownloadItemID: String?
    private var activeDownloadDestination: URL?

    init(isPrivate: Bool = false) {
        isPrivateBrowsing = isPrivate
        webView = WebViewFactory.makeWebView(isPrivate: isPrivate)
        super.init()
        webView.navigationDelegate = self
        webView.uiDelegate = self
        observeWebView()
    }

    func load(_ url: URL) {
        loadError = nil
        webContentCrashed = false
        lastLoadedURL = url
        webView.load(URLRequest(url: url))
    }

    func reload() {
        loadError = nil
        webContentCrashed = false
        webView.reload()
    }

    func stopLoading() {
        webView.stopLoading()
    }

    func goBack() {
        webView.goBack()
    }

    func goForward() {
        webView.goForward()
    }

    func recoverFromCrash() {
        if let lastLoadedURL {
            load(lastLoadedURL)
        } else {
            reload()
        }
    }

    /// Visible text of the current page, for on-device AI features.
    /// Returns nil when there is no committed page to read.
    func pageText() async -> String? {
        guard hasCommittedNavigation, !webContentCrashed else { return nil }
        return try? await webView.evaluateJavaScript(
            "document.body ? document.body.innerText : ''"
        ) as? String
    }

    private func observeWebView() {
        observations = [
            webView.observe(\.url, options: [.new]) { [weak self] _, _ in
                Task { @MainActor in
                    self?.currentURL = self?.webView.url
                }
            },
            webView.observe(\.title, options: [.new]) { [weak self] _, _ in
                Task { @MainActor in
                    self?.pageTitle = self?.webView.title ?? ""
                }
            },
            webView.observe(\.isLoading, options: [.new]) { [weak self] _, _ in
                Task { @MainActor in
                    self?.isLoading = self?.webView.isLoading ?? false
                }
            },
            webView.observe(\.estimatedProgress, options: [.new]) { [weak self] _, _ in
                Task { @MainActor in
                    self?.estimatedProgress = self?.webView.estimatedProgress ?? 0
                }
            },
            webView.observe(\.canGoBack, options: [.new]) { [weak self] _, _ in
                Task { @MainActor in
                    self?.canGoBack = self?.webView.canGoBack ?? false
                }
            },
            webView.observe(\.canGoForward, options: [.new]) { [weak self] _, _ in
                Task { @MainActor in
                    self?.canGoForward = self?.webView.canGoForward ?? false
                }
            },
        ]
    }
}

extension NavigationManager: WKNavigationDelegate {
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping @MainActor (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }

        let scheme = url.scheme?.lowercased()
        guard scheme == "http" || scheme == "https" else {
            if navigationAction.navigationType == .linkActivated {
                NSWorkspace.shared.open(url)
            }
            decisionHandler(.cancel)
            return
        }

        if navigationAction.targetFrame == nil {
            pendingMainFrameNavigation = true
            webView.load(navigationAction.request)
            decisionHandler(.cancel)
            return
        }

        pendingMainFrameNavigation = navigationAction.targetFrame?.isMainFrame ?? false
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        loadError = nil
        webContentCrashed = false
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        hasCommittedNavigation = true
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        hasCommittedNavigation = true
        if pendingMainFrameNavigation {
            pendingMainFrameNavigation = false
            recordHistoryIfNeeded()
        }
        Task { @MainActor in
            dominantColor = await PageColorSampler.sample(webView: webView)
        }
    }

    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        download.delegate = self
    }

    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        download.delegate = self
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping @MainActor (WKNavigationResponsePolicy) -> Void
    ) {
        guard let responseURL = navigationResponse.response.url,
              let scheme = responseURL.scheme?.lowercased(),
              scheme == "http" || scheme == "https"
        else {
            decisionHandler(.cancel)
            return
        }
        if navigationResponse.canShowMIMEType {
            pendingDownloadURL = nil
            decisionHandler(.allow)
        } else {
            pendingDownloadURL = responseURL
            decisionHandler(.download)
        }
    }

    private func recordHistoryIfNeeded() {
        guard !isPrivateBrowsing,
              let url = webView.url,
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https"
        else { return }
        HistoryStore.shared.record(url: url, title: webView.title ?? pageTitle)
    }

    func cancelDownload(itemID: String) -> Bool {
        guard activeDownloadItemID == itemID, let download = activeDownload else { return false }
        download.cancel()
        activeDownload = nil
        activeDownloadItemID = nil
        activeDownloadDestination = nil
        if let item = DownloadStore.shared.items.first(where: { $0.id == itemID }) {
            DownloadStore.shared.update(item, status: .cancelled, completedAt: Date())
        }
        return true
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let nsError = error as NSError
        guard !(nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled) else { return }
        loadError = error.localizedDescription
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        let nsError = error as NSError
        guard !(nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled) else { return }
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        webContentCrashed = true
        isLoading = false
        estimatedProgress = 0
    }

    func webView(
        _ webView: WKWebView,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping @MainActor (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        completionHandler(.performDefaultHandling, nil)
    }
}

extension NavigationManager {
    func requestPermission(
        _ type: PermissionManager.PermissionType,
        for origin: String,
        completion: @escaping @MainActor (Bool) -> Void
    ) {
        if let stored = PermissionManager.shared.decision(for: type, origin: origin) {
            completion(stored == .allow)
            return
        }

        let alert = NSAlert()
        alert.messageText = "\"\(origin)\" would like to use your \(type.displayName.lowercased())"
        alert.informativeText = "You can change this later in Settings."
        alert.addButton(withTitle: "Allow")
        alert.addButton(withTitle: "Deny")
        let rememberCheckbox = NSButton(checkboxWithTitle: "Remember for this website", target: nil, action: nil)
        rememberCheckbox.state = .off
        alert.accessoryView = rememberCheckbox
        alert.window.initialFirstResponder = alert.window.contentView

        let response = alert.runModal()
        let allowed = response == .alertFirstButtonReturn
        if rememberCheckbox.state == .on {
            PermissionManager.shared.setDecision(allowed ? .allow : .deny, for: type, origin: origin)
        }
        completion(allowed)
    }
}

extension NavigationManager: WKUIDelegate {
    func webView(
        _ webView: WKWebView,
        requestMediaCapturePermissionFor origin: WKSecurityOrigin,
        initiatedByFrame frame: WKFrameInfo,
        type: WKMediaCaptureType,
        decisionHandler: @escaping @MainActor (WKPermissionDecision) -> Void
    ) {
        let permissionType: PermissionManager.PermissionType
        switch type {
        case .camera: permissionType = .camera
        case .microphone: permissionType = .microphone
        case .cameraAndMicrophone: permissionType = .cameraAndMicrophone
        @unknown default: permissionType = .cameraAndMicrophone
        }
        let originKey = "\(origin.protocol)://\(origin.host)"
        requestPermission(permissionType, for: originKey) { allowed in
            decisionHandler(allowed ? .grant : .deny)
        }
    }

    func webView(
        _ webView: WKWebView,
        requestGeolocationPermissionFor origin: WKSecurityOrigin,
        initiatedByFrame frame: WKFrameInfo,
        decisionHandler: @escaping @MainActor (WKPermissionDecision) -> Void
    ) {
        let originKey = "\(origin.protocol)://\(origin.host)"
        requestPermission(.geolocation, for: originKey) { allowed in
            decisionHandler(allowed ? .grant : .deny)
        }
    }

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        if let url = navigationAction.request.url {
            load(url)
        }
        return nil
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping @MainActor () -> Void
    ) {
        let alert = NSAlert()
        alert.messageText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
        completionHandler()
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping @MainActor (Bool) -> Void
    ) {
        let alert = NSAlert()
        alert.messageText = message
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        let response = alert.runModal()
        completionHandler(response == .alertFirstButtonReturn)
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping @MainActor (String?) -> Void
    ) {
        let alert = NSAlert()
        alert.messageText = prompt
        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 240, height: 24))
        textField.stringValue = defaultText ?? ""
        alert.accessoryView = textField
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        let response = alert.runModal()
        completionHandler(response == .alertFirstButtonReturn ? textField.stringValue : nil)
    }

    func webView(
        _ webView: WKWebView,
        runOpenPanelWith parameters: WKOpenPanelParameters,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping @MainActor ([URL]?) -> Void
    ) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = parameters.allowsMultipleSelection
        panel.begin { response in
            completionHandler(response == .OK ? panel.urls : nil)
        }
    }
}

extension NavigationManager: WKDownloadDelegate {
    func download(
        _ download: WKDownload,
        decideDestinationUsing response: URLResponse,
        suggestedFilename: String,
        completionHandler: @escaping @MainActor (URL?) -> Void
    ) {
        activeDownload = download

        let url = pendingDownloadURL ?? response.url ?? URL(fileURLWithPath: "/")
        let item = DownloadStore.shared.begin(url: url, suggestedFilename: suggestedFilename)
        activeDownloadItemID = item.id
        pendingDownloadURL = nil

        let destination = Self.uniqueDestination(in: Self.downloadsDirectory, filename: suggestedFilename)
        activeDownloadDestination = destination
        completionHandler(destination)
    }

    func download(_ download: WKDownload, didReceive response: URLResponse) {
        guard let itemID = activeDownloadItemID,
              let item = DownloadStore.shared.items.first(where: { $0.id == itemID })
        else { return }
        let total = response.expectedContentLength > 0 ? response.expectedContentLength : nil
        DownloadStore.shared.updateProgress(item, bytesReceived: 0, totalBytes: total)
    }

    func download(
        _ download: WKDownload,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard let itemID = activeDownloadItemID,
              let item = DownloadStore.shared.items.first(where: { $0.id == itemID })
        else { return }
        let total = totalBytesExpectedToWrite > 0 ? totalBytesExpectedToWrite : nil
        DownloadStore.shared.updateProgress(item, bytesReceived: totalBytesWritten, totalBytes: total)
    }

    func downloadDidFinish(_ download: WKDownload) {
        completeActiveDownload(status: .completed)
    }

    func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        completeActiveDownload(status: .failed)
    }

    private func completeActiveDownload(status: DownloadStatus) {
        guard let itemID = activeDownloadItemID,
              let item = DownloadStore.shared.items.first(where: { $0.id == itemID })
        else { return }
        activeDownload = nil
        activeDownloadItemID = nil
        DownloadStore.shared.update(
            item,
            status: status,
            destinationPath: activeDownloadDestination?.path,
            completedAt: Date()
        )
        activeDownloadDestination = nil
    }

    private static var downloadsDirectory: URL {
        FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
    }

    private static func uniqueDestination(in directory: URL, filename: String) -> URL {
        let base = (filename as NSString).deletingPathExtension
        let ext = (filename as NSString).pathExtension
        var candidate = directory.appendingPathComponent(filename)
        var counter = 1
        while FileManager.default.fileExists(atPath: candidate.path) {
            let name = ext.isEmpty ? "\(base) (\(counter))" : "\(base) (\(counter)).\(ext)"
            candidate = directory.appendingPathComponent(name)
            counter += 1
        }
        return candidate
    }
}
