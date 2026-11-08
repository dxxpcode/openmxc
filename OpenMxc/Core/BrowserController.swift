import SwiftUI

@Observable
@MainActor
final class BrowserController {
    let tabManager = TabManager()

    var sidebarIsVisible = true
    private(set) var sidebarWidth: CGFloat = BrowserConstants.sidebarDefaultWidth

    init() {
        applyStressTabsArgumentIfPresent()
    }

    var selectedNavigation: NavigationManager? {
        tabManager.selectedTab?.navigation
    }

    func toggleSidebar() {
        withAnimation(.easeInOut(duration: 0.2)) {
            sidebarIsVisible.toggle()
        }
    }

    func setSidebarWidth(_ width: CGFloat) {
        sidebarWidth = min(
            max(width, BrowserConstants.sidebarMinimumWidth),
            BrowserConstants.sidebarMaximumWidth
        )
    }

    func navigate(to input: String) {
        guard let url = SearchService.resolve(input) else { return }
        if let selectedTab = tabManager.selectedTab {
            selectedTab.navigation.load(url)
        } else {
            tabManager.newTab(url: url)
        }
    }

    func newTab() {
        tabManager.newTab()
    }

    func closeSelectedTab() {
        guard let selectedTab = tabManager.selectedTab else { return }
        tabManager.closeTab(selectedTab)
    }

    private func applyStressTabsArgumentIfPresent() {
        guard let argument = ProcessInfo.processInfo.arguments
            .first(where: { $0.hasPrefix("--stress-tabs=") }),
            let count = Int(argument.dropFirst("--stress-tabs=".count)),
            count > 0
        else { return }

        for index in 0..<count {
            tabManager.newTab(url: URL(string: "https://example.com/?tab=\(index)"))
        }
    }
}
