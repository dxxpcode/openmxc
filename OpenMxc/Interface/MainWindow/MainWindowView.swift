import SwiftUI

struct MainWindowView: View {
    @Environment(BrowserController.self) private var controller

    var body: some View {
        Group {
            if let tab = controller.tabManager.selectedTab {
                WebViewContainer(webView: tab.navigation.webView)
                    .id(tab.id)
            } else {
                Color(nsColor: .windowBackgroundColor)
            }
        }
        .frame(
            minWidth: BrowserConstants.minimumWindowWidth,
            minHeight: BrowserConstants.minimumWindowHeight
        )
    }
}
