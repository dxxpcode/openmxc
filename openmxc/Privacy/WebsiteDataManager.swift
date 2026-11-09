import Foundation
import WebKit

/// Clears website data managed by WebKit (cookies, caches, storage).
/// Never touches the application database.
@MainActor
enum WebsiteDataManager {
    static func clearAllData() async {
        let store = WKWebsiteDataStore.default()
        let records = await withCheckedContinuation { continuation in
            store.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
                continuation.resume(returning: records)
            }
        }
        await withCheckedContinuation { continuation in
            store.removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), for: records) {
                continuation.resume()
            }
        }
    }

    static func dataRecordCount() async -> Int {
        await withCheckedContinuation { continuation in
            WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
                continuation.resume(returning: records.count)
            }
        }
    }
}
