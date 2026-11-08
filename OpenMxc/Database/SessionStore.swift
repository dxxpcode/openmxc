import Foundation

struct SavedTab: Hashable {
    let url: URL?
    let title: String?
    let isPinned: Bool
    let isMuted: Bool
}

struct SavedWindow {
    let tabs: [SavedTab]
    let selectedIndex: Int
}

/// Persists window/tab state to SQLite so browsing sessions survive relaunches.
/// Private windows (Phase 6) are never registered here.
@MainActor
final class SessionStore {
    static let shared = SessionStore(database: .shared)

    private let database: Database
    private var pendingWindows: [SavedWindow] = []
    private var controllers: [ObjectIdentifier: WeakController] = [:]

    private final class WeakController {
        weak var value: BrowserController?
        init(_ value: BrowserController) { self.value = value }
    }

    init(database: Database) {
        self.database = database
        loadPendingWindows()
    }

    /// Call once at launch, before any window is created.
    private func loadPendingWindows() {
        let windowRows = (try? database.query("""
            SELECT id, selected_position FROM browser_windows ORDER BY position ASC
            """)) ?? []

        pendingWindows = windowRows.compactMap { windowRow in
            guard let windowID = windowRow["id"]?.string else { return nil }
            let tabRows = (try? database.query("""
                SELECT url, title, is_pinned, is_muted FROM browser_tabs
                WHERE window_id = ? ORDER BY position ASC
                """, arguments: [.text(windowID)])) ?? []

            let tabs = tabRows.map { row in
                SavedTab(
                    url: row["url"]?.string.flatMap(URL.init(string:)),
                    title: row["title"]?.string,
                    isPinned: row["is_pinned"]?.bool ?? false,
                    isMuted: row["is_muted"]?.bool ?? false
                )
            }
            let selected = Int(windowRow["selected_position"]?.int ?? 0)
            return SavedWindow(tabs: tabs, selectedIndex: selected)
        }
    }

    /// Each new window claims the next saved window, in creation order.
    func nextWindowSession() -> SavedWindow? {
        guard !pendingWindows.isEmpty else { return nil }
        return pendingWindows.removeFirst()
    }

    func register(_ controller: BrowserController) {
        controllers[ObjectIdentifier(controller)] = WeakController(controller)
    }

    func unregister(_ controller: BrowserController) {
        controllers.removeValue(forKey: ObjectIdentifier(controller))
    }

    func allControllers() -> [BrowserController] {
        controllers = controllers.filter { $0.value.value != nil }
        return controllers.values.compactMap(\.value)
    }

    /// Rewrites the session tables from live controllers. Called on termination.
    func saveAll() {
        controllers = controllers.filter { $0.value.value != nil }
        guard !controllers.isEmpty else { return }

        let ordered = controllers.values.compactMap(\.value)
        try? database.execute("BEGIN")
        do {
            try database.execute("DELETE FROM browser_tabs")
            try database.execute("DELETE FROM browser_windows")

            for (windowPosition, controller) in ordered.enumerated() {
                let windowID = UUID().uuidString
                let selectedPosition = controller.tabManager.tabs.firstIndex {
                    $0.id == controller.tabManager.selectedTabID
                } ?? 0
                try database.execute(
                    """
                    INSERT INTO browser_windows (id, position, is_private, selected_position, created_at)
                    VALUES (?, ?, 0, ?, ?)
                    """,
                    arguments: [
                        .text(windowID),
                        .integer(Int64(windowPosition)),
                        .integer(Int64(selectedPosition)),
                        .fromTimestamp(Date()),
                    ]
                )
                for (tabPosition, tab) in controller.tabManager.tabs.enumerated() {
                    let url = tab.navigation.currentURL ?? tab.navigation.lastLoadedURL
                    try database.execute(
                        """
                        INSERT INTO browser_tabs
                            (id, window_id, position, url, title, is_pinned, is_muted, created_at)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                        """,
                        arguments: [
                            .text(tab.id.uuidString),
                            .text(windowID),
                            .integer(Int64(tabPosition)),
                            url.map { SQLValue.text($0.absoluteString) } ?? .null,
                            .text(tab.displayTitle),
                            .integer(tab.isPinned ? 1 : 0),
                            .integer(tab.isMuted ? 1 : 0),
                            .fromTimestamp(Date()),
                        ]
                    )
                }
            }
            try database.execute("COMMIT")
        } catch {
            try? database.execute("ROLLBACK")
        }
    }

    func clear() {
        pendingWindows.removeAll()
        try? database.execute("DELETE FROM browser_tabs")
        try? database.execute("DELETE FROM browser_windows")
    }
}
