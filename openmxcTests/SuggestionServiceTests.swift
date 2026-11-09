import XCTest
@testable import openmxc

@MainActor
final class SuggestionServiceTests: XCTestCase {
    private func favorite(_ title: String, _ urlString: String) -> Favorite {
        Favorite(title: title, url: URL(string: urlString)!, position: 0)
    }

    private func history(_ title: String, _ urlString: String) -> HistoryEntry {
        HistoryEntry(
            id: UUID().uuidString,
            url: URL(string: urlString)!,
            title: title,
            visitedAt: Date()
        )
    }

    func testEmptyQueryReturnsNothing() {
        let results = SuggestionService.suggestions(
            for: "   ",
            favorites: [favorite("GitHub", "https://github.com")],
            history: [history("Apple", "https://apple.com")]
        )
        XCTAssertTrue(results.isEmpty)
    }

    func testMatchesTitleHostAndUrl() {
        let favorites = [favorite("GitHub", "https://github.com")]
        let history = [
            history("Apple", "https://www.apple.com"),
            history("News", "https://example.com/news"),
        ]

        XCTAssertEqual(SuggestionService.suggestions(for: "git", favorites: favorites, history: history).count, 1)
        XCTAssertEqual(SuggestionService.suggestions(for: "apple.com", favorites: [], history: history).first?.title, "Apple")
        XCTAssertEqual(SuggestionService.suggestions(for: "example", favorites: [], history: history).first?.title, "News")
    }

    func testFavoritesRankBeforeHistoryAndDuplicatesAreRemoved() {
        let shared = "https://github.com"
        let favorites = [favorite("GitHub", shared)]
        let history = [history("GitHub - dxxpcode", shared), history("GitHub Blog", "https://github.blog")]

        let results = SuggestionService.suggestions(for: "github", favorites: favorites, history: history)

        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].kind, .favorite)
        XCTAssertEqual(results[0].title, "GitHub")
        XCTAssertEqual(results[1].kind, .history)
        XCTAssertEqual(results[1].title, "GitHub Blog")
    }

    func testRespectsLimit() {
        let entries = (1...10).map { history("Site \($0)", "https://site\($0).com") }
        let results = SuggestionService.suggestions(for: "site", favorites: [], history: entries, limit: 3)
        XCTAssertEqual(results.count, 3)
    }

    func testStripsWwwFromDisplayHost() {
        let results = SuggestionService.suggestions(
            for: "apple",
            favorites: [],
            history: [history("Apple", "https://www.apple.com")]
        )
        XCTAssertEqual(results.first?.host, "apple.com")
    }
}
