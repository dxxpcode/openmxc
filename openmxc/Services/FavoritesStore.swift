import Foundation

struct Favorite: Identifiable, Hashable {
    let id: UUID
    var title: String
    var url: URL
    var position: Int

    init(id: UUID = UUID(), title: String, url: URL, position: Int) {
        self.id = id
        self.title = title
        self.url = url
        self.position = position
    }
}

@Observable
@MainActor
final class FavoritesStore {
    static let shared = FavoritesStore(database: .shared)

    private let database: Database?
    private(set) var favorites: [Favorite] = []

    /// `database == nil` keeps favorites in memory only (used by tests).
    init(database: Database?) {
        self.database = database
        reload()
    }

    func reload() {
        favorites = (try? fetchAll()) ?? []
    }

    func favorite(for url: URL) -> Favorite? {
        favorites.first { $0.url == url }
    }

    @discardableResult
    func add(title: String, url: URL) -> Favorite {
        if let index = favorites.firstIndex(where: { $0.url == url }) {
            favorites[index].title = title
            persistTitle(favorites[index])
            return favorites[index]
        }
        let favorite = Favorite(title: title, url: url, position: favorites.count)
        favorites.append(favorite)
        insert(favorite)
        return favorite
    }

    func remove(_ favorite: Favorite) {
        favorites.removeAll { $0.id == favorite.id }
        normalizePositions()
        try? database?.execute("DELETE FROM favorites WHERE id = ?", arguments: [.text(favorite.id.uuidString)])
        rewritePositions()
    }

    func move(fromOffsets offsets: IndexSet, toOffset destination: Int) {
        favorites.move(fromOffsets: offsets, toOffset: destination)
        normalizePositions()
        rewritePositions()
    }

    func move(_ favorite: Favorite, before target: Favorite) {
        guard favorite.id != target.id,
              favorites.contains(where: { $0.id == favorite.id }),
              favorites.contains(where: { $0.id == target.id })
        else { return }
        guard let sourceIndex = favorites.firstIndex(where: { $0.id == favorite.id }) else { return }
        let moved = favorites.remove(at: sourceIndex)
        let adjustedTarget = favorites.firstIndex(where: { $0.id == target.id }) ?? favorites.count
        favorites.insert(moved, at: adjustedTarget)
        normalizePositions()
        rewritePositions()
    }

    func updateAddress(_ favorite: Favorite, url: URL) {
        guard let index = favorites.firstIndex(where: { $0.id == favorite.id }) else { return }
        favorites[index].url = url
        try? database?.execute(
            "UPDATE favorites SET url = ? WHERE id = ?",
            arguments: [.text(url.absoluteString), .text(favorite.id.uuidString)]
        )
    }

    // MARK: - Persistence

    private func fetchAll() throws -> [Favorite] {
        guard let database else { return [] }
        let rows = try database.query("SELECT id, title, url, position FROM favorites ORDER BY position ASC")
        return rows.compactMap { row in
            guard let idString = row["id"]?.string,
                  let id = UUID(uuidString: idString),
                  let title = row["title"]?.string,
                  let urlString = row["url"]?.string,
                  let url = URL(string: urlString)
            else { return nil }
            return Favorite(id: id, title: title, url: url, position: Int(row["position"]?.int ?? 0))
        }
    }

    private func insert(_ favorite: Favorite) {
        try? database?.execute(
            "INSERT INTO favorites (id, title, url, position, created_at) VALUES (?, ?, ?, ?, ?)",
            arguments: [
                .text(favorite.id.uuidString),
                .text(favorite.title),
                .text(favorite.url.absoluteString),
                .integer(Int64(favorite.position)),
                .fromTimestamp(Date()),
            ]
        )
    }

    private func persistTitle(_ favorite: Favorite) {
        try? database?.execute(
            "UPDATE favorites SET title = ? WHERE id = ?",
            arguments: [.text(favorite.title), .text(favorite.id.uuidString)]
        )
    }

    private func rewritePositions() {
        guard let database else { return }
        for favorite in favorites {
            try? database.execute(
                "UPDATE favorites SET position = ? WHERE id = ?",
                arguments: [.integer(Int64(favorite.position)), .text(favorite.id.uuidString)]
            )
        }
    }

    private func normalizePositions() {
        for index in favorites.indices {
            favorites[index].position = index
        }
    }
}
