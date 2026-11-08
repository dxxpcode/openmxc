import WebKit

@MainActor
enum WebViewFactory {
    static func makeWebView(isPrivate: Bool = false) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.isElementFullscreenEnabled = true
        configuration.websiteDataStore = isPrivate ? .nonPersistent() : .default()

        if !isPrivate, let ruleList = TrackingProtection.shared.ruleList {
            configuration.userContentController.add(ruleList)
        }

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = true
        webView.autoresizingMask = [.width, .height]
        if !isPrivate {
            TrackingProtection.shared.apply(to: webView)
        }
        return webView
    }
}
