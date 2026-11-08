import XCTest
@testable import OpenMxc

@MainActor
final class TabManagerTests: XCTestCase {
    func testStartsWithOneTab() {
        let manager = TabManager()
        XCTAssertEqual(manager.tabs.count, 1)
        XCTAssertNotNil(manager.selectedTab)
    }

    func testNewTabSelectsIt() {
        let manager = TabManager()
        let tab = manager.newTab()
        XCTAssertEqual(manager.tabs.count, 2)
        XCTAssertEqual(manager.selectedTabID, tab.id)
    }

    func testCloseTabSelectsNeighbor() {
        let manager = TabManager()
        let first = manager.tabs[0]
        let second = manager.newTab()
        manager.closeTab(first)
        XCTAssertEqual(manager.tabs.count, 1)
        XCTAssertEqual(manager.selectedTabID, second.id)
    }

    func testCloseLastTabCreatesFreshTab() {
        let manager = TabManager()
        manager.closeTab(manager.tabs[0])
        XCTAssertEqual(manager.tabs.count, 1)
        XCTAssertNotEqual(manager.selectedTabID, nil)
    }

    func testPinMovesTabToPinnedSection() {
        let manager = TabManager()
        let second = manager.newTab()
        manager.togglePin(second)
        XCTAssertEqual(manager.pinnedTabs.map(\.id), [second.id])
        XCTAssertEqual(manager.unpinnedTabs.count, 1)
        XCTAssertEqual(manager.tabs.first?.id, second.id)
    }

    func testUnpinMovesTabBackToRegularSection() {
        let manager = TabManager()
        let second = manager.newTab()
        manager.togglePin(second)
        manager.togglePin(second)
        XCTAssertTrue(manager.pinnedTabs.isEmpty)
        XCTAssertEqual(manager.unpinnedTabs.count, 2)
    }

    func testDuplicateTabCopiesURL() {
        let manager = TabManager()
        let tab = manager.tabs[0]
        tab.navigation.load(URL(string: "https://example.com/")!)
        let duplicate = manager.duplicateTab(tab)
        XCTAssertEqual(duplicate.navigation.lastLoadedURL, URL(string: "https://example.com/"))
        XCTAssertEqual(manager.selectedTabID, duplicate.id)
    }

    func testCloseOtherTabsKeepsPinned() {
        let manager = TabManager()
        let first = manager.tabs[0]
        let second = manager.newTab()
        let third = manager.newTab()
        manager.togglePin(first)
        manager.closeOtherTabs(keeping: second)
        XCTAssertEqual(Set(manager.tabs.map(\.id)), [first.id, second.id])
        XCTAssertEqual(manager.selectedTabID, second.id)
        _ = third
    }
}
