import Foundation

struct HistoryEntry: Identifiable, Hashable {
    let id: String
    let url: URL
    let title: String
    let visitedAt: Date
}

@Observable
@MainActor
final class HistoryStore {
    static let shared = HistoryStore(database: .shared)

    private let database: Database
    private(set) var entries: [HistoryEntry] = []

    init(database: Database) {
        self.database = database
        reload()
    }

    func reload() {
        entries = (try? fetchAll()) ?? []
    }

    func record(url: URL, title: String) {
        let id = UUID().uuidString
        try? database.execute(
            "INSERT INTO history_visits (id, url, title, visited_at) VALUES (?, ?, ?, ?)",
            arguments: [.text(id), .text(url.absoluteString), .text(title), .fromTimestamp(Date())]
        )
        reload()
    }

    func delete(_ entry: HistoryEntry) {
        try? database.execute("DELETE FROM history_visits WHERE id = ?", arguments: [.text(entry.id)])
        reload()
    }

    func clearAll() {
        try? database.execute("DELETE FROM history_visits")
        reload()
    }

    enum ClearRange {
        case olderThan(Date)
        case all
    }

    func clear(_ range: ClearRange) {
        switch range {
        case .all:
            try? database.execute("DELETE FROM history_visits")
        case .olderThan(let date):
            try? database.execute(
                "DELETE FROM history_visits WHERE visited_at < ?",
                arguments: [.fromTimestamp(date)]
            )
        }
        reload()
    }

    func search(_ query: String) -> [HistoryEntry] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return entries }
        return entries.filter {
            $0.title.localizedCaseInsensitiveContains(trimmed)
                || $0.url.absoluteString.localizedCaseInsensitiveContains(trimmed)
        }
    }

    private func fetchAll() throws -> [HistoryEntry] {
        let rows = try database.query("""
            SELECT id, url, title, visited_at FROM history_visits
            ORDER BY visited_at DESC, rowid DESC
            """)
        return rows.compactMap { row in
            guard let urlString = row["url"]?.string,
                  let url = URL(string: urlString),
                  let visitedAt = row["visited_at"]?.date
            else { return nil }
            return HistoryEntry(
                id: row["id"]?.string ?? UUID().uuidString,
                url: url,
                title: row["title"]?.string ?? url.host() ?? url.absoluteString,
                visitedAt: visitedAt
            )
        }
    }
}
