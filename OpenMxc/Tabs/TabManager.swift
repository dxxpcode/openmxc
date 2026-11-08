import Foundation

@Observable
@MainActor
final class TabManager {
    private(set) var tabs: [TabModel] = []
    private(set) var selectedTabID: UUID?

    init() {
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
        let tab = TabModel(url: url)
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
        }
    }

    func select(_ tab: TabModel) {
        guard tabs.contains(where: { $0.id == tab.id }) else { return }
        selectedTabID = tab.id
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
