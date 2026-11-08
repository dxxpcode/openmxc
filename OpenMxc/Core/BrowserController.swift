import SwiftUI

@Observable
@MainActor
final class BrowserController {
    let tabManager: TabManager
    let favorites = FavoritesStore.shared
    let isPrivate: Bool

    var sidebarIsVisible = true
    private(set) var sidebarWidth: CGFloat = BrowserConstants.sidebarDefaultWidth
    var librarySection: LibrarySection?

    init(isPrivate: Bool = false) {
        self.isPrivate = isPrivate
        self.tabManager = TabManager(isPrivate: isPrivate)
        if !isPrivate {
            if hasStressTabsArgument {
                applyStressTabsArgumentIfPresent()
            } else if let savedWindow = SessionStore.shared.nextWindowSession() {
                tabManager.restoreWindow(savedWindow)
            }
            SessionStore.shared.register(self)
        }
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

    func showLibrary(_ section: LibrarySection) {
        librarySection = section
    }

    func navigate(to input: String) {
        librarySection = nil
        guard let url = SearchService.resolve(input) else { return }
        if let selectedTab = tabManager.selectedTab {
            selectedTab.navigation.load(url)
        } else {
            tabManager.newTab(url: url)
        }
    }

    func newTab() {
        librarySection = nil
        tabManager.newTab()
    }

    func closeSelectedTab() {
        guard let selectedTab = tabManager.selectedTab else { return }
        tabManager.closeTab(selectedTab)
    }

    func selectTab(at index: Int) {
        librarySection = nil
        tabManager.selectTab(at: index)
    }

    func selectAdjacentTab(_ offset: Int) {
        librarySection = nil
        tabManager.selectAdjacentTab(offset)
    }

    var currentPageIsFavorite: Bool {
        guard let url = tabManager.selectedTab?.navigation.currentURL else { return false }
        return favorites.favorite(for: url) != nil
    }

    func toggleFavorite() {
        guard let tab = tabManager.selectedTab,
              let url = tab.navigation.currentURL ?? tab.navigation.lastLoadedURL
        else { return }
        if let existing = favorites.favorite(for: url) {
            favorites.remove(existing)
        } else {
            favorites.add(title: tab.displayTitle, url: url)
        }
    }

    func openFavorite(_ favorite: Favorite) {
        librarySection = nil
        if let selectedTab = tabManager.selectedTab {
            selectedTab.navigation.load(favorite.url)
        } else {
            tabManager.newTab(url: favorite.url)
        }
    }

    var hasStressTabsArgument: Bool {
        ProcessInfo.processInfo.arguments.contains { $0.hasPrefix("--stress-tabs=") }
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
