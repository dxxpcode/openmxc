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
            if let savedWindow = SessionStore.shared.nextWindowSession() {
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
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        navigationToken = UUID()
        let token = navigationToken

        if SearchService.directURL(for: trimmed) != nil {
            loadResolved(SearchService.resolve(trimmed), token: token)
            return
        }

        Task { @MainActor in
            if let url = await SmartAddressService.shared.resolve(query: trimmed) {
                loadResolved(url, token: token)
            } else if let url = SearchService.resolve(trimmed) {
                loadResolved(url, token: token)
            }
        }
    }

    private var navigationToken = UUID()

    private func loadResolved(_ url: URL?, token: UUID) {
        guard token == navigationToken, let url else { return }
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

}
