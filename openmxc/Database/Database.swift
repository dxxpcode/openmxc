import Foundation
import SQLite3

enum DatabaseError: Error, CustomStringConvertible {
    case cannotOpen(String)
    case prepareFailed(String)
    case stepFailed(String)

    var description: String {
        switch self {
        case .cannotOpen(let message), .prepareFailed(let message), .stepFailed(let message):
            return message
        }
    }
}

enum SQLValue {
    case text(String)
    case integer(Int64)
    case real(Double)
    case null

    var string: String? {
        if case .text(let value) = self { return value }
        return nil
    }

    var int: Int64 {
        switch self {
        case .integer(let value): return value
        case .real(let value): return Int64(value)
        case .text(let value): return Int64(value) ?? 0
        case .null: return 0
        }
    }

    var bool: Bool { int != 0 }

    var isNull: Bool {
        if case .null = self { return true }
        return false
    }

    static func fromTimestamp(_ date: Date) -> SQLValue {
        .integer(Int64(date.timeIntervalSince1970))
    }

    var date: Date? {
        switch self {
        case .integer(let value): return Date(timeIntervalSince1970: TimeInterval(value))
        case .real(let value): return Date(timeIntervalSince1970: value)
        default: return nil
        }
    }
}

/// SQLite is compiled in serialized threading mode, and all access is funnelled
/// through this class, so sharing the handle is safe.
extension Database: @unchecked Sendable {}

final class Database {
    private var handle: OpaquePointer?

    static let shared: Database = {
        let directory = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("OPENMXC", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let path = directory.appendingPathComponent("browser.sqlite").path
        do {
            return try Database(path: path)
        } catch {
            fatalError("Failed to open browser database: \(error)")
        }
    }()

    init(path: String) throws {
        var handle: OpaquePointer?
        guard sqlite3_open(path, &handle) == SQLITE_OK else {
            let message = handle.flatMap { String(cString: sqlite3_errmsg($0)) } ?? "unknown"
            if let handle { sqlite3_close(handle) }
            throw DatabaseError.cannotOpen("Cannot open database at \(path): \(message)")
        }
        self.handle = handle
        try execute("PRAGMA journal_mode = WAL")
        try execute("PRAGMA foreign_keys = ON")
        try migrate()
    }

    deinit {
        sqlite3_close(handle)
    }

    func execute(_ sql: String, arguments: [SQLValue] = []) throws {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(handle, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed(errorMessage(sql))
        }
        defer { sqlite3_finalize(statement) }
        try bind(arguments, to: statement)
        while true {
            let result = sqlite3_step(statement)
            if result == SQLITE_ROW { continue }
            guard result == SQLITE_DONE else {
                throw DatabaseError.stepFailed(errorMessage(sql))
            }
            return
        }
    }

    func query(_ sql: String, arguments: [SQLValue] = []) throws -> [[String: SQLValue]] {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(handle, sql, -1, &statement, nil) == SQLITE_OK else {
            throw DatabaseError.prepareFailed(errorMessage(sql))
        }
        defer { sqlite3_finalize(statement) }
        try bind(arguments, to: statement)

        var rows: [[String: SQLValue]] = []
        let columnCount = sqlite3_column_count(statement)
        while true {
            let result = sqlite3_step(statement)
            if result == SQLITE_DONE { break }
            guard result == SQLITE_ROW else {
                throw DatabaseError.stepFailed(errorMessage(sql))
            }
            var row: [String: SQLValue] = [:]
            for index in 0..<columnCount {
                let name = String(cString: sqlite3_column_name(statement, index))
                row[name] = value(at: index, in: statement)
            }
            rows.append(row)
        }
        return rows
    }

    func scalar<T>(_ sql: String, arguments: [SQLValue] = [], transform: (SQLValue) -> T) throws -> T? {
        let rows = try query(sql, arguments: arguments)
        guard let first = rows.first?.values.first else { return nil }
        return transform(first)
    }

    private func bind(_ values: [SQLValue], to statement: OpaquePointer?) throws {
        for (offset, value) in values.enumerated() {
            let index = Int32(offset + 1)
            let result: Int32
            switch value {
            case .text(let text):
                result = sqlite3_bind_text(statement, index, text, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self))
            case .integer(let integer):
                result = sqlite3_bind_int64(statement, index, integer)
            case .real(let real):
                result = sqlite3_bind_double(statement, index, real)
            case .null:
                result = sqlite3_bind_null(statement, index)
            }
            guard result == SQLITE_OK else {
                throw DatabaseError.stepFailed("Failed to bind parameter \(offset + 1)")
            }
        }
    }

    private func value(at index: Int32, in statement: OpaquePointer?) -> SQLValue {
        switch sqlite3_column_type(statement, index) {
        case SQLITE_INTEGER:
            return .integer(sqlite3_column_int64(statement, index))
        case SQLITE_FLOAT:
            return .real(sqlite3_column_double(statement, index))
        case SQLITE_NULL:
            return .null
        default:
            let text = sqlite3_column_text(statement, index)
            return .text(text.map { String(cString: $0) } ?? "")
        }
    }

    private func errorMessage(_ sql: String) -> String {
        let message = handle.flatMap { String(cString: sqlite3_errmsg($0)) } ?? "unknown error"
        return "Database error near '\(sql.prefix(60))': \(message)"
    }

    private func migrate() throws {
        try execute("""
            CREATE TABLE IF NOT EXISTS schema_migrations (
                version INTEGER PRIMARY KEY,
                applied_at INTEGER NOT NULL
            )
            """)
        for migration in DatabaseMigrations.all {
            let applied = try scalar(
                "SELECT COUNT(*) FROM schema_migrations WHERE version = ?",
                arguments: [.integer(Int64(migration.version))]
            ) { $0.int } ?? 0
            guard applied == 0 else { continue }
            try execute("BEGIN")
            do {
                for statement in migration.statements {
                    try execute(statement)
                }
                try execute(
                    "INSERT INTO schema_migrations (version, applied_at) VALUES (?, ?)",
                    arguments: [.integer(Int64(migration.version)), .fromTimestamp(Date())]
                )
                try execute("COMMIT")
            } catch {
                try? execute("ROLLBACK")
                throw error
            }
        }
    }
}
