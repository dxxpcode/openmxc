import WebKit

@MainActor
enum WebViewFactory {
    static func makeWebView() -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.isElementFullscreenEnabled = true
        configuration.websiteDataStore = .default()

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = true
        webView.autoresizingMask = [.width, .height]
        return webView
    }
}
