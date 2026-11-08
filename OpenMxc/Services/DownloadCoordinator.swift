import Foundation

/// Routes download actions (cancel) to the tab that owns the in-flight download.
@MainActor
enum DownloadCoordinator {
    static func cancel(_ item: DownloadItem) {
        for controller in SessionStore.shared.allControllers() {
            for tab in controller.tabManager.tabs {
                if tab.navigation.cancelDownload(itemID: item.id) {
                    return
                }
            }
        }
        DownloadStore.shared.update(item, status: .cancelled, completedAt: Date())
    }
}
