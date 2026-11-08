import Foundation

struct SearchEngine: Identifiable, Hashable {
    let id: String
    let name: String
    let template: String
}

enum SearchService {
    static let defaultEngine = SearchEngine(
        id: "duckduckgo",
        name: "DuckDuckGo",
        template: "https://duckduckgo.com/?q={query}"
    )

    static func resolve(_ input: String) -> URL? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let url = directURL(for: trimmed) {
            return url
        }
        return searchURL(for: trimmed)
    }

    static func directURL(for input: String) -> URL? {
        if input.contains("://") {
            guard let url = URL(string: input),
                  let scheme = url.scheme?.lowercased(),
                  scheme == "http" || scheme == "https",
                  url.host != nil
            else { return nil }
            return url
        }

        guard !input.contains(" ") else { return nil }

        let candidate = "https://" + input
        guard let url = URL(string: candidate), let host = url.host?.lowercased(), !host.isEmpty else {
            return nil
        }

        let looksLikeHost = host.contains(".")
            || host == "localhost"
            || host.hasSuffix(".local")
            || url.port != nil

        guard looksLikeHost else { return nil }

        if host == "localhost" || host == "127.0.0.1" || host == "::1" {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.scheme = "http"
            return components?.url ?? url
        }
        return url
    }

    static func searchURL(for query: String, engine: SearchEngine = defaultEngine) -> URL? {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = engine.template.replacingOccurrences(of: "{query}", with: encoded)
        return URL(string: urlString)
    }
}
