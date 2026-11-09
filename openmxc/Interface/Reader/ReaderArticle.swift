import Foundation

/// A page distilled to its article content for reader mode.
struct ReaderArticle: Equatable {
    enum Block: Equatable {
        case heading(level: Int, text: String)
        case paragraph(String)
        case quote(String)
        case code(String)
        case list([String])
        case image(url: String, alt: String)
    }

    var title: String
    var byline: String?
    var siteName: String?
    var url: URL
    var blocks: [Block]

    /// Parses the JSON produced by `ReaderExtractor.extractionScript`.
    static func parse(json: String, url: URL) -> ReaderArticle? {
        guard let data = json.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }

        let rawBlocks = object["blocks"] as? [[String: Any]] ?? []
        let blocks = rawBlocks.compactMap(parseBlock)
        guard !blocks.isEmpty else { return nil }

        let title = (object["title"] as? String)
            .flatMap { $0.isEmpty ? nil : $0 }
            ?? url.host() ?? url.absoluteString

        return ReaderArticle(
            title: title,
            byline: nonEmpty(object["byline"] as? String),
            siteName: nonEmpty(object["siteName"] as? String),
            url: url,
            blocks: blocks
        )
    }

    private static func nonEmpty(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func parseBlock(_ object: [String: Any]) -> Block? {
        let type = object["type"] as? String
        switch type {
        case "heading":
            guard let text = nonEmpty(object["text"] as? String) else { return nil }
            let level = min(max(object["level"] as? Int ?? 2, 1), 4)
            return .heading(level: level, text: text)
        case "paragraph":
            guard let text = nonEmpty(object["text"] as? String) else { return nil }
            return .paragraph(text)
        case "quote":
            guard let text = nonEmpty(object["text"] as? String) else { return nil }
            return .quote(text)
        case "code":
            guard let text = nonEmpty(object["text"] as? String) else { return nil }
            return .code(text)
        case "list":
            let items = (object["items"] as? [String])?.compactMap(nonEmpty) ?? []
            return items.isEmpty ? nil : .list(items)
        case "image":
            guard let imageURL = nonEmpty(object["url"] as? String),
                  imageURL.hasPrefix("http")
            else { return nil }
            return .image(url: imageURL, alt: object["alt"] as? String ?? "")
        default:
            return nil
        }
    }
}
