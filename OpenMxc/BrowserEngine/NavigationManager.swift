import AppKit
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

    private(set) var lastLoadedURL: URL?

    private var observations: [NSKeyValueObservation] = []

    override init() {
        webView = WebViewFactory.makeWebView()
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
            webView.load(navigationAction.request)
            decisionHandler(.cancel)
            return
        }

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

extension NavigationManager: WKUIDelegate {
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
