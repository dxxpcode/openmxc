import XCTest
@testable import openmxc

final class SearchServiceTests: XCTestCase {
    func testResolvesFullHTTPURL() {
        XCTAssertEqual(
            SearchService.resolve("https://example.com/page?q=1")?.absoluteString,
            "https://example.com/page?q=1"
        )
    }

    func testResolvesBareDomainAsHTTPS() {
        XCTAssertEqual(
            SearchService.resolve("example.com")?.absoluteString,
            "https://example.com"
        )
    }

    func testResolvesDomainWithPath() {
        XCTAssertEqual(
            SearchService.resolve("example.com/path")?.absoluteString,
            "https://example.com/path"
        )
    }

    func testResolvesLocalhostWithPortAsHTTP() {
        XCTAssertEqual(
            SearchService.resolve("localhost:3000")?.absoluteString,
            "http://localhost:3000"
        )
    }

    func testResolvesLocalIPWithPortAsHTTP() {
        XCTAssertEqual(
            SearchService.resolve("127.0.0.1:8000")?.absoluteString,
            "http://127.0.0.1:8000"
        )
    }

    func testSearchesForMultiWordInput() {
        let url = SearchService.resolve("weather tomorrow")
        XCTAssertEqual(url?.host, "duckduckgo.com")
        XCTAssertTrue(url?.absoluteString.contains("weather%20tomorrow") ?? false)
    }

    func testSearchesForSingleWordWithoutDot() {
        let url = SearchService.resolve("apple")
        XCTAssertEqual(url?.host, "duckduckgo.com")
        XCTAssertTrue(url?.absoluteString.contains("q=apple") ?? false)
    }

    func testEmptyInputReturnsNil() {
        XCTAssertNil(SearchService.resolve(""))
        XCTAssertNil(SearchService.resolve("   "))
    }

    func testUnsupportedSchemeIsNotOpenedDirectly() {
        let url = SearchService.resolve("ftp://example.com")
        XCTAssertNotEqual(url?.scheme, "ftp")
    }
}
