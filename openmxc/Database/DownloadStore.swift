import Foundation

enum DownloadStatus: String {
    case inProgress
    case completed
    case failed
    case cancelled
}

struct DownloadItem: Identifiable, Hashable {
    let id: String
    var filename: String
    let url: URL
    var destinationPath: String?
    var totalBytes: Int64?
    var bytesReceived: Int64
    var status: DownloadStatus
    let createdAt: Date
    var completedAt: Date?

    var fileSize: Int64? {
        if let totalBytes, totalBytes > 0 { return totalBytes }
        guard let destinationPath else { return nil }
        let size = (try? FileManager.default.attributesOfItem(atPath: destinationPath)[.size] as? NSNumber)?.int64Value
        return size
    }
}

@Observable
@MainActor
final class DownloadStore {
    static let shared = DownloadStore(database: .shared)

    private let database: Database
    private(set) var items: [DownloadItem] = []

    init(database: Database) {
        self.database = database
        reload()
        pruneStaleInProgress()
    }

    func reload() {
        items = (try? fetchAll()) ?? []
    }

    @discardableResult
    func begin(url: URL, suggestedFilename: String) -> DownloadItem {
        let id = UUID().uuidString
        try? database.execute(
            """
            INSERT INTO downloads (id, filename, url, status, created_at)
            VALUES (?, ?, ?, ?, ?)
            """,
            arguments: [
                .text(id),
                .text(suggestedFilename),
                .text(url.absoluteString),
                .text(DownloadStatus.inProgress.rawValue),
                .fromTimestamp(Date()),
            ]
        )
        reload()
        return items.first { $0.id == id } ?? DownloadItem(
            id: id, filename: suggestedFilename, url: url, destinationPath: nil,
            totalBytes: nil, bytesReceived: 0, status: .inProgress, createdAt: Date(), completedAt: nil
        )
    }

    func update(_ item: DownloadItem, status: DownloadStatus, destinationPath: String? = nil, completedAt: Date? = nil) {
        try? database.execute(
            """
            UPDATE downloads SET status = ?, destination_path = COALESCE(?, destination_path),
                completed_at = COALESCE(?, completed_at)
            WHERE id = ?
            """,
            arguments: [
                .text(status.rawValue),
                destinationPath.map(SQLValue.text) ?? .null,
                completedAt.map(SQLValue.fromTimestamp) ?? .null,
                .text(item.id),
            ]
        )
        reload()
    }

    func updateProgress(_ item: DownloadItem, bytesReceived: Int64, totalBytes: Int64? = nil) {
        if let totalBytes {
            try? database.execute(
                "UPDATE downloads SET bytes_received = ?, total_bytes = ? WHERE id = ?",
                arguments: [.integer(bytesReceived), .integer(totalBytes), .text(item.id)]
            )
        } else {
            try? database.execute(
                "UPDATE downloads SET bytes_received = ? WHERE id = ?",
                arguments: [.integer(bytesReceived), .text(item.id)]
            )
        }
        reload()
    }

    func remove(_ item: DownloadItem) {
        try? database.execute("DELETE FROM downloads WHERE id = ?", arguments: [.text(item.id)])
        reload()
    }

    func clearCompleted() {
        try? database.execute("DELETE FROM downloads WHERE status != ?", arguments: [.text(DownloadStatus.inProgress.rawValue)])
        reload()
    }

    /// Downloads interrupted by an app quit can never resume; mark them failed on launch.
    private func pruneStaleInProgress() {
        try? database.execute(
            "UPDATE downloads SET status = ?, completed_at = ? WHERE status = ?",
            arguments: [
                .text(DownloadStatus.failed.rawValue),
                .fromTimestamp(Date()),
                .text(DownloadStatus.inProgress.rawValue),
            ]
        )
    }

    private func fetchAll() throws -> [DownloadItem] {
        let rows = try database.query("""
            SELECT id, filename, url, destination_path, total_bytes, bytes_received,
                   status, created_at, completed_at
            FROM downloads ORDER BY created_at DESC
            """)
        return rows.compactMap { row in
            guard let urlString = row["url"]?.string,
                  let url = URL(string: urlString),
                  let filename = row["filename"]?.string,
                  let createdAt = row["created_at"]?.date,
                  let statusRaw = row["status"]?.string,
                  let status = DownloadStatus(rawValue: statusRaw)
            else { return nil }
            return DownloadItem(
                id: row["id"]?.string ?? UUID().uuidString,
                filename: filename,
                url: url,
                destinationPath: row["destination_path"]?.string,
                totalBytes: row["total_bytes"]?.isNull == false ? row["total_bytes"]?.int : nil,
                bytesReceived: row["bytes_received"]?.int ?? 0,
                status: status,
                createdAt: createdAt,
                completedAt: row["completed_at"]?.date
            )
        }
    }
}
