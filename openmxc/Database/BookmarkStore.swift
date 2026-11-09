import Foundation

struct BookmarkFolder: Identifiable, Hashable {
    let id: String
    var name: String
    let parentID: String?
    var position: Int
    let createdAt: Date
}

struct Bookmark: Identifiable, Hashable {
    let id: String
    var folderID: String?
    var title: String
    let url: URL
    var position: Int
    let createdAt: Date
    var updatedAt: Date
}

@Observable
@MainActor
final class BookmarkStore {
    static let shared = BookmarkStore(database: .shared)

    private let database: Database
    private(set) var folders: [BookmarkFolder] = []
    private(set) var bookmarks: [Bookmark] = []

    init(database: Database) {
        self.database = database
        reload()
    }

    func reload() {
        folders = (try? fetchFolders()) ?? []
        bookmarks = (try? fetchBookmarks()) ?? []
    }

    // MARK: - Folders

    @discardableResult
    func createFolder(name: String, parentID: String? = nil) -> BookmarkFolder? {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        let id = UUID().uuidString
        let siblings = folders.filter { $0.parentID == parentID }
        try? database.execute(
            "INSERT INTO bookmark_folders (id, parent_id, name, position, created_at) VALUES (?, ?, ?, ?, ?)",
            arguments: [
                .text(id),
                parentID.map(SQLValue.text) ?? .null,
                .text(trimmed),
                .integer(Int64(siblings.count)),
                .fromTimestamp(Date()),
            ]
        )
        reload()
        return folders.first { $0.id == id }
    }

    func renameFolder(_ folder: BookmarkFolder, name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        try? database.execute(
            "UPDATE bookmark_folders SET name = ? WHERE id = ?",
            arguments: [.text(trimmed), .text(folder.id)]
        )
        reload()
    }

    /// Deleting a folder moves its bookmarks to the folder's parent (SET NULL at root).
    func deleteFolder(_ folder: BookmarkFolder) {
        try? database.execute("DELETE FROM bookmark_folders WHERE id = ?", arguments: [.text(folder.id)])
        reload()
    }

    func childFolders(of parentID: String?) -> [BookmarkFolder] {
        folders.filter { $0.parentID == parentID }.sorted { $0.position < $1.position }
    }

    // MARK: - Bookmarks

    @discardableResult
    func addBookmark(title: String, url: URL, folderID: String? = nil) -> Bookmark? {
        guard let scheme = url.scheme, scheme == "http" || scheme == "https" else { return nil }
        if let existing = bookmarks.first(where: { $0.url == url && $0.folderID == folderID }) {
            updateBookmark(existing, title: title, url: url)
            return bookmarks.first { $0.id == existing.id }
        }
        let id = UUID().uuidString
        let siblings = bookmarks.filter { $0.folderID == folderID }
        let now = Date()
        try? database.execute(
            """
            INSERT INTO bookmarks (id, folder_id, title, url, position, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            arguments: [
                .text(id),
                folderID.map(SQLValue.text) ?? .null,
                .text(title),
                .text(url.absoluteString),
                .integer(Int64(siblings.count)),
                .fromTimestamp(now),
                .fromTimestamp(now),
            ]
        )
        reload()
        return bookmarks.first { $0.id == id }
    }

    func updateBookmark(_ bookmark: Bookmark, title: String, url: URL) {
        try? database.execute(
            "UPDATE bookmarks SET title = ?, url = ?, updated_at = ? WHERE id = ?",
            arguments: [.text(title), .text(url.absoluteString), .fromTimestamp(Date()), .text(bookmark.id)]
        )
        reload()
    }

    func moveBookmark(_ bookmark: Bookmark, toFolder folderID: String?) {
        let siblings = bookmarks.filter { $0.folderID == folderID && $0.id != bookmark.id }
        try? database.execute(
            "UPDATE bookmarks SET folder_id = ?, position = ? WHERE id = ?",
            arguments: [folderID.map(SQLValue.text) ?? .null, .integer(Int64(siblings.count)), .text(bookmark.id)]
        )
        reload()
    }

    func deleteBookmark(_ bookmark: Bookmark) {
        try? database.execute("DELETE FROM bookmarks WHERE id = ?", arguments: [.text(bookmark.id)])
        reload()
    }

    func search(_ query: String, folderID: String? = nil) -> [Bookmark] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        var results = bookmarks.filter { $0.folderID == folderID }
        if !trimmed.isEmpty {
            results = results.filter {
                $0.title.localizedCaseInsensitiveContains(trimmed)
                    || $0.url.absoluteString.localizedCaseInsensitiveContains(trimmed)
            }
        }
        return results.sorted { $0.position < $1.position }
    }

    /// Searches across every folder (used by the library search field).
    func allMatching(_ query: String) -> [Bookmark] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            return bookmarks.sorted { $0.position < $1.position }
        }
        return bookmarks.filter {
            $0.title.localizedCaseInsensitiveContains(trimmed)
                || $0.url.absoluteString.localizedCaseInsensitiveContains(trimmed)
        }
    }

    private func fetchFolders() throws -> [BookmarkFolder] {
        let rows = try database.query("""
            SELECT id, parent_id, name, position, created_at FROM bookmark_folders
            ORDER BY position ASC
            """)
        return rows.compactMap { row in
            guard let name = row["name"]?.string, let createdAt = row["created_at"]?.date else { return nil }
            return BookmarkFolder(
                id: row["id"]?.string ?? UUID().uuidString,
                name: name,
                parentID: row["parent_id"]?.string,
                position: Int(row["position"]?.int ?? 0),
                createdAt: createdAt
            )
        }
    }

    private func fetchBookmarks() throws -> [Bookmark] {
        let rows = try database.query("""
            SELECT id, folder_id, title, url, position, created_at, updated_at FROM bookmarks
            ORDER BY position ASC
            """)
        return rows.compactMap { row in
            guard let urlString = row["url"]?.string,
                  let url = URL(string: urlString),
                  let title = row["title"]?.string,
                  let createdAt = row["created_at"]?.date,
                  let updatedAt = row["updated_at"]?.date
            else { return nil }
            return Bookmark(
                id: row["id"]?.string ?? UUID().uuidString,
                folderID: row["folder_id"]?.string,
                title: title,
                url: url,
                position: Int(row["position"]?.int ?? 0),
                createdAt: createdAt,
                updatedAt: updatedAt
            )
        }
    }
}
