import XCTest
@testable import openmxc

@MainActor
final class DatabaseStoresTests: XCTestCase {
    private func makeDatabase() throws -> Database {
        try Database(path: ":memory:")
    }

    // MARK: - History

    func testHistoryRecordSearchDeleteAndClear() throws {
        let database = try makeDatabase()
        let store = HistoryStore(database: database)

        let url = URL(string: "https://example.com/article")!
        store.record(url: url, title: "Example Article")
        store.record(url: URL(string: "https://other.example")!, title: "Other")

        XCTAssertEqual(store.entries.count, 2)
        XCTAssertEqual(store.search("article").first?.title, "Example Article")

        store.delete(store.entries[0])
        XCTAssertEqual(store.entries.count, 1)

        store.clear(.olderThan(Date().addingTimeInterval(3600)))
        XCTAssertTrue(store.entries.isEmpty)
    }

    // MARK: - Bookmarks

    func testBookmarkFoldersAndDeletionPolicy() throws {
        let database = try makeDatabase()
        let store = BookmarkStore(database: database)

        let folder = store.createFolder(name: "Reading")
        XCTAssertNotNil(folder)

        let bookmark = store.addBookmark(
            title: "Example",
            url: URL(string: "https://example.com")!,
            folderID: folder?.id
        )
        XCTAssertNotNil(bookmark)

        // Deleting the folder moves its bookmarks to the top level (ON DELETE SET NULL).
        if let folder {
            store.deleteFolder(folder)
        }
        store.reload()
        XCTAssertEqual(store.bookmarks.first?.folderID, nil)

        if let bookmark {
            store.deleteBookmark(bookmark)
        }
        XCTAssertTrue(store.bookmarks.isEmpty)
    }

    func testBookmarkSearchAcrossFolders() throws {
        let database = try makeDatabase()
        let store = BookmarkStore(database: database)

        store.addBookmark(title: "Alpha", url: URL(string: "https://alpha.example")!)
        let folder = store.createFolder(name: "Work")
        store.addBookmark(title: "Beta", url: URL(string: "https://beta.example")!, folderID: folder?.id)

        XCTAssertEqual(store.allMatching("beta").count, 1)
        XCTAssertEqual(store.allMatching("").count, 2)
    }

    // MARK: - Reading List

    func testReadingListReadToggleAndRemove() throws {
        let database = try makeDatabase()
        let store = ReadingListStore(database: database)

        store.add(title: "Later", url: URL(string: "https://later.example")!)
        XCTAssertEqual(store.items.count, 1)
        XCTAssertFalse(store.items[0].isRead)

        // Adding the same URL again marks it unread rather than duplicating.
        store.add(title: "Later", url: URL(string: "https://later.example")!)
        XCTAssertEqual(store.items.count, 1)

        let item = store.items[0]
        store.setRead(item, isRead: true)
        XCTAssertTrue(store.items[0].isRead)

        store.remove(item)
        XCTAssertTrue(store.items.isEmpty)
    }

    // MARK: - Downloads

    func testDownloadsLifecycle() throws {
        let database = try makeDatabase()
        let store = DownloadStore(database: database)

        let item = store.begin(url: URL(string: "https://example.com/file.zip")!, suggestedFilename: "file.zip")
        XCTAssertEqual(item.status, .inProgress)
        XCTAssertEqual(store.items.count, 1)

        store.updateProgress(item, bytesReceived: 512, totalBytes: 1024)
        store.update(item, status: .completed, destinationPath: "/tmp/file.zip", completedAt: Date())

        XCTAssertEqual(store.items[0].status, .completed)
        XCTAssertEqual(store.items[0].fileSize, 1024)

        store.clearCompleted()
        XCTAssertTrue(store.items.isEmpty)
    }

    // MARK: - Favorites persistence

    func testFavoritesSurviveNewStoreInstance() throws {
        let database = try makeDatabase()
        let first = FavoritesStore(database: database)
        first.add(title: "Example", url: URL(string: "https://example.com")!)

        let second = FavoritesStore(database: database)
        XCTAssertEqual(second.favorites.map(\.title), ["Example"])
    }

    // MARK: - Migration

    func testMigrationsAreIdempotent() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("openmxc-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let path = directory.appendingPathComponent("browser.sqlite").path

        let first = try Database(path: path)
        let second = try Database(path: path)

        XCTAssertNoThrow(try first.query("SELECT COUNT(*) FROM schema_migrations"))
        XCTAssertNoThrow(try second.query("SELECT COUNT(*) FROM schema_migrations"))
    }
}
