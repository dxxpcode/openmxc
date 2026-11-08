import Foundation
import WebKit

/// Website permission decisions (camera, microphone, geolocation), persisted
/// per origin in the settings table. Absence of a decision means "ask".
@Observable
@MainActor
final class PermissionManager {
    static let shared = PermissionManager(database: .shared)

    enum PermissionType: String, CaseIterable {
        case camera
        case microphone
        case cameraAndMicrophone
        case geolocation

        var displayName: String {
            switch self {
            case .camera: return "Camera"
            case .microphone: return "Microphone"
            case .cameraAndMicrophone: return "Camera and Microphone"
            case .geolocation: return "Location"
            }
        }
    }

    enum Decision: String {
        case allow
        case deny
    }

    private let database: Database

    init(database: Database) {
        self.database = database
    }

    /// Origin key is "scheme://host" (no path), matching how websites identify themselves.
    static func originKey(for url: URL?) -> String? {
        guard let url, let scheme = url.scheme, let host = url.host, !host.isEmpty else { return nil }
        return "\(scheme)://\(host)"
    }

    func decision(for type: PermissionType, origin: String) -> Decision? {
        guard let raw = AppSettings.string(storageKey(type, origin), database: database) else { return nil }
        return Decision(rawValue: raw)
    }

    func setDecision(_ decision: Decision?, for type: PermissionType, origin: String) {
        AppSettings.set(storageKey(type, origin), value: decision?.rawValue, database: database)
    }

    func allDecisions() -> [(origin: String, type: PermissionType, decision: Decision)] {
        let rows = (try? database.query("SELECT key, value FROM settings WHERE key LIKE 'permission.%'")) ?? []
        return rows.compactMap { row in
            guard let key = row["key"]?.string,
                  let value = row["value"]?.string,
                  let decision = Decision(rawValue: value),
                  key.hasPrefix("permission.")
            else { return nil }
            let rest = String(key.dropFirst("permission.".count))
            guard let separator = rest.firstIndex(of: ".") else { return nil }
            let typeRaw = String(rest[..<separator])
            let origin = String(rest[rest.index(after: separator)...])
            guard let type = PermissionType(rawValue: typeRaw) else { return nil }
            return (origin: origin, type: type, decision: decision)
        }
    }

    func reset(origin: String) {
        for type in PermissionType.allCases {
            setDecision(nil, for: type, origin: origin)
        }
    }

    private func storageKey(_ type: PermissionType, _ origin: String) -> String {
        "permission.\(type.rawValue).\(origin)"
    }
}
