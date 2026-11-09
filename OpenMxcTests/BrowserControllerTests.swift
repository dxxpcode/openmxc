import XCTest
@testable import OpenMxc

@MainActor
final class BrowserControllerTests: XCTestCase {
    func testSidebarWidthClampsToAllowedRange() {
        let controller = BrowserController(loadHomepage: false)

        controller.setSidebarWidth(500)
        XCTAssertEqual(controller.sidebarWidth, BrowserConstants.sidebarMaximumWidth)

        controller.setSidebarWidth(10)
        XCTAssertEqual(controller.sidebarWidth, BrowserConstants.sidebarMinimumWidth)

        controller.setSidebarWidth(240)
        XCTAssertEqual(controller.sidebarWidth, 240)
    }

    func testSidebarToggles() {
        let controller = BrowserController(loadHomepage: false)
        XCTAssertTrue(controller.sidebarIsVisible)

        controller.toggleSidebar()
        XCTAssertFalse(controller.sidebarIsVisible)
    }
}
