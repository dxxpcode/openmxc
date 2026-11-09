import XCTest
@testable import openmxc

final class ReaderArticleTests: XCTestCase {
    private let url = URL(string: "https://example.com/story")!

    func testParsesAllBlockTypes() throws {
        let json = """
        {
            "title": "A Great Story",
            "byline": "Jane Doe",
            "siteName": "Example News",
            "blocks": [
                { "type": "heading", "level": 2, "text": "Section" },
                { "type": "paragraph", "text": "First paragraph." },
                { "type": "quote", "text": "A memorable line." },
                { "type": "code", "text": "let x = 1" },
                { "type": "list", "items": ["one", "two"] },
                { "type": "image", "url": "https://example.com/a.png", "alt": "A photo" }
            ]
        }
        """
        let article = try XCTUnwrap(ReaderArticle.parse(json: json, url: url))
        XCTAssertEqual(article.title, "A Great Story")
        XCTAssertEqual(article.byline, "Jane Doe")
        XCTAssertEqual(article.siteName, "Example News")
        XCTAssertEqual(article.blocks, [
            .heading(level: 2, text: "Section"),
            .paragraph("First paragraph."),
            .quote("A memorable line."),
            .code("let x = 1"),
            .list(["one", "two"]),
            .image(url: "https://example.com/a.png", alt: "A photo"),
        ])
    }

    func testEmptyBlocksReturnsNil() {
        let json = #"{"title": "Empty", "blocks": []}"#
        XCTAssertNil(ReaderArticle.parse(json: json, url: url))
    }

    func testInvalidJSONReturnsNil() {
        XCTAssertNil(ReaderArticle.parse(json: "not json", url: url))
    }

    func testTitleFallsBackToHost() throws {
        let json = #"{"title": "", "blocks": [{"type": "paragraph", "text": "Body."}]}"#
        let article = try XCTUnwrap(ReaderArticle.parse(json: json, url: url))
        XCTAssertEqual(article.title, "example.com")
        XCTAssertNil(article.byline)
        XCTAssertNil(article.siteName)
    }

    func testSkipsInvalidBlocksAndUnsafeImages() throws {
        let json = """
        {
            "title": "T",
            "blocks": [
                { "type": "unknown", "text": "ignored" },
                { "type": "paragraph", "text": "  " },
                { "type": "image", "url": "javascript:alert(1)", "alt": "bad" },
                { "type": "image", "url": "data:image/png;base64,x", "alt": "bad" },
                { "type": "list", "items": [] },
                { "type": "paragraph", "text": "Kept." }
            ]
        }
        """
        let article = try XCTUnwrap(ReaderArticle.parse(json: json, url: url))
        XCTAssertEqual(article.blocks, [.paragraph("Kept.")])
    }

    func testHeadingLevelIsClamped() throws {
        let json = """
        {
            "title": "T",
            "blocks": [
                { "type": "heading", "level": 9, "text": "Deep" },
                { "type": "heading", "level": 0, "text": "Shallow" }
            ]
        }
        """
        let article = try XCTUnwrap(ReaderArticle.parse(json: json, url: url))
        XCTAssertEqual(article.blocks, [
            .heading(level: 4, text: "Deep"),
            .heading(level: 1, text: "Shallow"),
        ])
    }
}
