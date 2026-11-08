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
    private(set) var favorites: [Favorite] = []

    func favorite(for url: URL) -> Favorite? {
        favorites.first { $0.url == url }
    }

    @discardableResult
    func add(title: String, url: URL) -> Favorite {
        if let index = favorites.firstIndex(where: { $0.url == url }) {
            favorites[index].title = title
            return favorites[index]
        }
        let favorite = Favorite(title: title, url: url, position: favorites.count)
        favorites.append(favorite)
        return favorite
    }

    func remove(_ favorite: Favorite) {
        favorites.removeAll { $0.id == favorite.id }
        normalizePositions()
    }

    func move(fromOffsets offsets: IndexSet, toOffset destination: Int) {
        favorites.move(fromOffsets: offsets, toOffset: destination)
        normalizePositions()
    }

    func move(_ favorite: Favorite, before target: Favorite) {
        guard favorite.id != target.id,
              let sourceIndex = favorites.firstIndex(where: { $0.id == favorite.id }),
              let targetIndex = favorites.firstIndex(where: { $0.id == target.id })
        else { return }
        let moved = favorites.remove(at: sourceIndex)
        let adjustedTarget = favorites.firstIndex(where: { $0.id == target.id }) ?? targetIndex
        favorites.insert(moved, at: adjustedTarget)
        normalizePositions()
    }

    func updateAddress(_ favorite: Favorite, url: URL) {
        guard let index = favorites.firstIndex(where: { $0.id == favorite.id }) else { return }
        favorites[index].url = url
    }

    private func normalizePositions() {
        for index in favorites.indices {
            favorites[index].position = index
        }
    }
}
