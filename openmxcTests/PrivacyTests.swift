import XCTest
@testable import openmxc

@MainActor
final class PrivacyTests: XCTestCase {
    func testPermissionDecisionsPersistPerOriginAndType() throws {
        let database = try Database(path: ":memory:")
        let manager = PermissionManager(database: database)
        let origin = "https://example.com"

        XCTAssertNil(manager.decision(for: .camera, origin: origin))
        manager.setDecision(.allow, for: .camera, origin: origin)
        manager.setDecision(.deny, for: .geolocation, origin: origin)

        XCTAssertEqual(manager.decision(for: .camera, origin: origin), .allow)
        XCTAssertEqual(manager.decision(for: .geolocation, origin: origin), .deny)
        XCTAssertNil(manager.decision(for: .microphone, origin: origin))

        let persisted = PermissionManager(database: database)
        XCTAssertEqual(persisted.decision(for: .camera, origin: origin), .allow)
    }

    func testPermissionResetClearsAllTypesForOrigin() throws {
        let database = try Database(path: ":memory:")
        let manager = PermissionManager(database: database)
        let origin = "https://example.com"

        manager.setDecision(.allow, for: .camera, origin: origin)
        manager.setDecision(.deny, for: .geolocation, origin: origin)
        manager.reset(origin: origin)

        XCTAssertNil(manager.decision(for: .camera, origin: origin))
        XCTAssertNil(manager.decision(for: .geolocation, origin: origin))
    }

    func testPrivateTabsUseNonPersistentBrowsing() {
        let manager = TabManager(isPrivate: true)
        XCTAssertTrue(manager.tabs.allSatisfy { $0.navigation.isPrivateBrowsing })
        XCTAssertTrue(manager.newTab().navigation.isPrivateBrowsing)
    }

    func testRegularTabsAreNotPrivate() {
        let manager = TabManager()
        XCTAssertFalse(manager.tabs[0].navigation.isPrivateBrowsing)
    }

    func testTrackingProtectionDefaultsToEnabled() throws {
        let database = try Database(path: ":memory:")
        XCTAssertTrue(TrackingProtection(database: database).isEnabled)
    }

    func testTrackingProtectionTogglePersists() throws {
        let database = try Database(path: ":memory:")
        let protection = TrackingProtection(database: database)
        protection.setEnabled(false)
        XCTAssertFalse(TrackingProtection(database: database).isEnabled)
    }
}
