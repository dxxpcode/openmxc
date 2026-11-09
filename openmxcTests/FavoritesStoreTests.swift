import XCTest
@testable import OpenMxc

@MainActor
final class FavoritesStoreTests: XCTestCase {
    private func makeStore() -> FavoritesStore {
        FavoritesStore(database: nil)
    }

    func testAddAppendsWithSequentialPositions() {
        let store = makeStore()
        let first = store.add(title: "One", url: URL(string: "https://one.example")!)
        let second = store.add(title: "Two", url: URL(string: "https://two.example")!)

        XCTAssertEqual(store.favorites, [first, second])
        XCTAssertEqual(first.position, 0)
        XCTAssertEqual(second.position, 1)
    }

    func testAddSameURLUpdatesTitleInsteadOfDuplicating() {
        let store = makeStore()
        let url = URL(string: "https://example.com")!
        store.add(title: "Old", url: url)
        store.add(title: "New", url: url)

        XCTAssertEqual(store.favorites.count, 1)
        XCTAssertEqual(store.favorites.first?.title, "New")
    }

    func testRemoveReordersPositions() {
        let store = makeStore()
        let first = store.add(title: "One", url: URL(string: "https://one.example")!)
        store.add(title: "Two", url: URL(string: "https://two.example")!)
        let third = store.add(title: "Three", url: URL(string: "https://three.example")!)

        store.remove(first)

        XCTAssertEqual(store.favorites.map(\.title), ["Two", "Three"])
        XCTAssertEqual(store.favorites.map(\.position), [0, 1])
        XCTAssertNotNil(store.favorite(for: third.url))
    }

    func testMoveFromOffsetsReorders() {
        let store = makeStore()
        store.add(title: "One", url: URL(string: "https://one.example")!)
        store.add(title: "Two", url: URL(string: "https://two.example")!)
        store.add(title: "Three", url: URL(string: "https://three.example")!)

        store.move(fromOffsets: IndexSet(integer: 0), toOffset: 3)

        XCTAssertEqual(store.favorites.map(\.title), ["Two", "Three", "One"])
        XCTAssertEqual(store.favorites.map(\.position), [0, 1, 2])
    }

    func testMoveBeforeSwapsNeighbors() {
        let store = makeStore()
        let first = store.add(title: "One", url: URL(string: "https://one.example")!)
        let second = store.add(title: "Two", url: URL(string: "https://two.example")!)
        store.add(title: "Three", url: URL(string: "https://three.example")!)

        store.move(second, before: first)

        XCTAssertEqual(store.favorites.map(\.title), ["Two", "One", "Three"])
    }

    func testUpdateAddress() {
        let store = makeStore()
        let favorite = store.add(title: "Example", url: URL(string: "https://example.com")!)
        let newURL = URL(string: "https://example.org/path")!

        store.updateAddress(favorite, url: newURL)

        XCTAssertEqual(store.favorite(for: newURL)?.id, favorite.id)
        XCTAssertNil(store.favorite(for: URL(string: "https://example.com")!))
    }
}
