import Foundation

@Observable
@MainActor
final class TabManager {
    private(set) var tabs: [TabModel] = []
    private(set) var selectedTabID: UUID?
    private let isPrivate: Bool

    init(isPrivate: Bool = false) {
        self.isPrivate = isPrivate
        newTab()
    }

    var selectedTab: TabModel? {
        tabs.first { $0.id == selectedTabID }
    }

    var pinnedTabs: [TabModel] {
        tabs.filter(\.isPinned)
    }

    var unpinnedTabs: [TabModel] {
        tabs.filter { !$0.isPinned }
    }

    @discardableResult
    func newTab(url: URL? = nil) -> TabModel {
        let tab = TabModel(url: url, isPrivate: isPrivate)
        tabs.append(tab)
        selectedTabID = tab.id
        return tab
    }

    func closeTab(_ tab: TabModel) {
        guard let index = tabs.firstIndex(where: { $0.id == tab.id }) else { return }
        let wasSelected = tab.id == selectedTabID
        tabs.remove(at: index)

        if tabs.isEmpty {
            newTab()
            return
        }

        if wasSelected {
            let nextIndex = min(index, tabs.count - 1)
            selectedTabID = tabs[nextIndex].id
            tabs[nextIndex].activate()
        }
    }

    func select(_ tab: TabModel) {
        guard tabs.contains(where: { $0.id == tab.id }) else { return }
        selectedTabID = tab.id
        tab.activate()
    }

    func togglePin(_ tab: TabModel) {
        tab.isPinned.toggle()
        normalizeOrder()
    }

    @discardableResult
    func duplicateTab(_ tab: TabModel) -> TabModel {
        let duplicate = newTab(url: tab.navigation.lastLoadedURL ?? tab.navigation.currentURL)
        if let index = tabs.firstIndex(where: { $0.id == tab.id }) {
            tabs.removeAll { $0.id == duplicate.id }
            tabs.insert(duplicate, at: index + 1)
        }
        selectedTabID = duplicate.id
        return duplicate
    }

    func closeOtherTabs(keeping tab: TabModel) {
        let pinnedIDs = Set(tabs.filter(\.isPinned).map(\.id))
        tabs = tabs.filter { $0.id == tab.id || pinnedIDs.contains($0.id) }
        selectedTabID = tab.id
    }

    func closeAllTabs() {
        tabs.forEach { $0.navigation.webView.stopLoading() }
        tabs.removeAll()
        newTab()
    }

    /// Replaces all tabs with a restored session. Only the selected tab gets a URL
    /// to load immediately; the rest load lazily when selected.
    func restoreWindow(_ savedWindow: SavedWindow) {
        tabs.forEach { $0.navigation.webView.stopLoading() }
        tabs.removeAll()

        for savedTab in savedWindow.tabs {
            let tab = TabModel(isPrivate: isPrivate)
            tab.restore(url: savedTab.url, title: savedTab.title, isPinned: savedTab.isPinned, isMuted: savedTab.isMuted)
            tabs.append(tab)
        }

        if tabs.isEmpty {
            newTab()
            return
        }

        let clamped = min(max(savedWindow.selectedIndex, 0), tabs.count - 1)
        selectedTabID = tabs[clamped].id
        tabs[clamped].activate()
    }

    func selectTab(at index: Int) {
        guard tabs.indices.contains(index) else { return }
        selectedTabID = tabs[index].id
        tabs[index].activate()
    }

    func selectAdjacentTab(_ offset: Int) {
        guard let currentID = selectedTabID,
              let currentIndex = tabs.firstIndex(where: { $0.id == currentID })
        else { return }
        let count = tabs.count
        let nextIndex = (currentIndex + offset + count) % count
        selectTab(at: nextIndex)
    }

    func moveTab(_ draggedID: UUID, onto targetID: UUID) {
        guard draggedID != targetID,
              let draggedIndex = tabs.firstIndex(where: { $0.id == draggedID }),
              tabs.contains(where: { $0.id == targetID })
        else { return }

        let dragged = tabs.remove(at: draggedIndex)
        guard let newTargetIndex = tabs.firstIndex(where: { $0.id == targetID }) else {
            tabs.insert(dragged, at: draggedIndex)
            return
        }
        tabs.insert(dragged, at: newTargetIndex)
    }

    private func normalizeOrder() {
        let pinned = tabs.filter(\.isPinned)
        let unpinned = tabs.filter { !$0.isPinned }
        tabs = pinned + unpinned
    }
}
