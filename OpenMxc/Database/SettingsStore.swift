import Foundation

/// Key-value settings persisted in the `settings` table.
/// Simple system preferences may use UserDefaults instead; this is for
/// browser-owned configuration that must survive reinstalls of defaults.
enum AppSettings {
    static func string(_ key: String, database: Database = .shared) -> String? {
        let rows = try? database.query(
            "SELECT value FROM settings WHERE key = ?",
            arguments: [.text(key)]
        )
        return rows?.first?["value"]?.string
    }

    static func bool(_ key: String, default defaultValue: Bool, database: Database = .shared) -> Bool {
        guard let raw = string(key, database: database) else { return defaultValue }
        return raw == "1" || raw.lowercased() == "true"
    }

    static func set(_ key: String, value: String?, database: Database = .shared) {
        if let value {
            try? database.execute(
                """
                INSERT INTO settings (key, value, updated_at) VALUES (?, ?, ?)
                ON CONFLICT(key) DO UPDATE SET value = excluded.value, updated_at = excluded.updated_at
                """,
                arguments: [.text(key), .text(value), .fromTimestamp(Date())]
            )
        } else {
            try? database.execute("DELETE FROM settings WHERE key = ?", arguments: [.text(key)])
        }
    }

    static func setBool(_ key: String, _ value: Bool, database: Database = .shared) {
        set(key, value: value ? "1" : "0", database: database)
    }
}
