import Foundation

struct DatabaseMigration {
    let version: Int
    let statements: [String]
}

enum DatabaseMigrations {
    static let all: [DatabaseMigration] = [
        DatabaseMigration(version: 1, statements: [
            """
            CREATE TABLE favorites (
                id TEXT PRIMARY KEY,
                title TEXT NOT NULL,
                url TEXT NOT NULL,
                position INTEGER NOT NULL,
                created_at INTEGER NOT NULL
            )
            """,
            """
            CREATE TABLE bookmark_folders (
                id TEXT PRIMARY KEY,
                parent_id TEXT REFERENCES bookmark_folders(id) ON DELETE CASCADE,
                name TEXT NOT NULL,
                position INTEGER NOT NULL,
                created_at INTEGER NOT NULL
            )
            """,
            """
            CREATE TABLE bookmarks (
                id TEXT PRIMARY KEY,
                folder_id TEXT REFERENCES bookmark_folders(id) ON DELETE SET NULL,
                title TEXT NOT NULL,
                url TEXT NOT NULL,
                position INTEGER NOT NULL,
                created_at INTEGER NOT NULL,
                updated_at INTEGER NOT NULL
            )
            """,
            """
            CREATE TABLE history_visits (
                id TEXT PRIMARY KEY,
                url TEXT NOT NULL,
                title TEXT NOT NULL,
                visited_at INTEGER NOT NULL
            )
            """,
            "CREATE INDEX history_visits_visited_at ON history_visits(visited_at DESC)",
            """
            CREATE TABLE reading_list (
                id TEXT PRIMARY KEY,
                title TEXT NOT NULL,
                url TEXT NOT NULL,
                added_at INTEGER NOT NULL,
                is_read INTEGER NOT NULL DEFAULT 0
            )
            """,
            """
            CREATE TABLE downloads (
                id TEXT PRIMARY KEY,
                filename TEXT NOT NULL,
                url TEXT NOT NULL,
                destination_path TEXT,
                total_bytes INTEGER,
                bytes_received INTEGER NOT NULL DEFAULT 0,
                status TEXT NOT NULL,
                created_at INTEGER NOT NULL,
                completed_at INTEGER
            )
            """,
            """
            CREATE TABLE browser_windows (
                id TEXT PRIMARY KEY,
                position INTEGER NOT NULL,
                is_private INTEGER NOT NULL DEFAULT 0,
                selected_position INTEGER NOT NULL DEFAULT 0,
                created_at INTEGER NOT NULL
            )
            """,
            """
            CREATE TABLE browser_tabs (
                id TEXT PRIMARY KEY,
                window_id TEXT NOT NULL REFERENCES browser_windows(id) ON DELETE CASCADE,
                position INTEGER NOT NULL,
                url TEXT,
                title TEXT,
                is_pinned INTEGER NOT NULL DEFAULT 0,
                is_muted INTEGER NOT NULL DEFAULT 0,
                created_at INTEGER NOT NULL
            )
            """,
            "CREATE INDEX browser_tabs_window ON browser_tabs(window_id, position)",
            """
            CREATE TABLE search_engines (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                search_url_template TEXT NOT NULL,
                is_default INTEGER NOT NULL DEFAULT 0
            )
            """,
            """
            CREATE TABLE settings (
                key TEXT PRIMARY KEY,
                value TEXT,
                updated_at INTEGER NOT NULL
            )
            """,
            """
            INSERT INTO search_engines (id, name, search_url_template, is_default) VALUES
                ('duckduckgo', 'DuckDuckGo', 'https://duckduckgo.com/?q={query}', 1),
                ('google', 'Google', 'https://www.google.com/search?q={query}', 0)
            """,
        ]),
        DatabaseMigration(version: 2, statements: [
            """
            INSERT OR IGNORE INTO search_engines (id, name, search_url_template, is_default) VALUES
                ('brave', 'Brave Search', 'https://search.brave.com/search?q={query}', 0),
                ('bing', 'Bing', 'https://www.bing.com/search?q={query}', 0)
            """,
        ]),
    ]
}
