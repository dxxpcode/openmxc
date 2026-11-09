import Foundation

/// One row in the address bar's suggestion dropdown.
struct AddressSuggestion: Identifiable, Hashable {
    enum Kind: Hashable {
        case favorite
        case history
    }

    let id: String
    let kind: Kind
    let title: String
    let url: URL
    let host: String
}

/// Ranks favorites and history matches for the address bar as the user types.
/// Pure and synchronous so it stays trivial to test; the view appends a
/// "Search for …" row itself when nothing matches.
enum SuggestionService {
    static func suggestions(
        for query: String,
        favorites: [Favorite],
        history: [HistoryEntry],
        limit: Int = 5
    ) -> [AddressSuggestion] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, limit > 0 else { return [] }
        let needle = trimmed.lowercased()

        var seen = Set<String>()
        var results: [AddressSuggestion] = []

        // Favorites first (user-curated, stable order), then history (recency order).
        for favorite in favorites {
            guard results.count < limit else { break }
            let key = favorite.url.absoluteString
            guard !seen.contains(key), matches(favorite.title, host: favorite.url.host(), query: needle) else { continue }
            seen.insert(key)
            results.append(AddressSuggestion(
                id: "favorite-\(favorite.id.uuidString)",
                kind: .favorite,
                title: favorite.title,
                url: favorite.url,
                host: displayHost(for: favorite.url)
            ))
        }

        for entry in history {
            guard results.count < limit else { break }
            let key = entry.url.absoluteString
            guard !seen.contains(key), matches(entry.title, host: entry.url.host(), query: needle) else { continue }
            seen.insert(key)
            results.append(AddressSuggestion(
                id: "history-\(entry.id)",
                kind: .history,
                title: entry.title,
                url: entry.url,
                host: displayHost(for: entry.url)
            ))
        }

        return results
    }

    private static func matches(_ title: String, host: String?, query: String) -> Bool {
        title.lowercased().contains(query)
            || (host ?? "").lowercased().contains(query)
    }

    private static func displayHost(for url: URL) -> String {
        let host = url.host() ?? url.absoluteString
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }
}
