import Foundation

struct ReadingListItem: Identifiable, Hashable {
    let id: String
    var title: String
    let url: URL
    let addedAt: Date
    var isRead: Bool
}

@Observable
@MainActor
final class ReadingListStore {
    static let shared = ReadingListStore(database: .shared)

    private let database: Database
    private(set) var items: [ReadingListItem] = []

    init(database: Database) {
        self.database = database
        reload()
    }

    func reload() {
        items = (try? fetchAll()) ?? []
    }

    func add(title: String, url: URL) {
        let existing = items.first { $0.url == url }
        if let existing {
            setRead(existing, isRead: false)
            return
        }
        try? database.execute(
            "INSERT INTO reading_list (id, title, url, added_at, is_read) VALUES (?, ?, ?, ?, 0)",
            arguments: [
                .text(UUID().uuidString),
                .text(title),
                .text(url.absoluteString),
                .fromTimestamp(Date()),
            ]
        )
        reload()
    }

    func setRead(_ item: ReadingListItem, isRead: Bool) {
        try? database.execute(
            "UPDATE reading_list SET is_read = ? WHERE id = ?",
            arguments: [.integer(isRead ? 1 : 0), .text(item.id)]
        )
        reload()
    }

    func remove(_ item: ReadingListItem) {
        try? database.execute("DELETE FROM reading_list WHERE id = ?", arguments: [.text(item.id)])
        reload()
    }

    func search(_ query: String) -> [ReadingListItem] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return items }
        return items.filter {
            $0.title.localizedCaseInsensitiveContains(trimmed)
                || $0.url.absoluteString.localizedCaseInsensitiveContains(trimmed)
        }
    }

    private func fetchAll() throws -> [ReadingListItem] {
        let rows = try database.query("""
            SELECT id, title, url, added_at, is_read FROM reading_list
            ORDER BY is_read ASC, added_at DESC
            """)
        return rows.compactMap { row in
            guard let urlString = row["url"]?.string,
                  let url = URL(string: urlString),
                  let addedAt = row["added_at"]?.date
            else { return nil }
            return ReadingListItem(
                id: row["id"]?.string ?? UUID().uuidString,
                title: row["title"]?.string ?? url.host() ?? url.absoluteString,
                url: url,
                addedAt: addedAt,
                isRead: row["is_read"]?.bool ?? false
            )
        }
    }
}
