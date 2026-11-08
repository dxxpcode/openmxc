import Foundation
import FoundationModels

/// Draft shape the on-device model fills in for address-bar smart resolution.
@Generable
struct AddressResolutionDraft {
    @Guide(description: "true only when the input unambiguously refers to one specific website or web service")
    var isDirectSite: Bool

    @Guide(description: "The site's canonical https URL when isDirectSite is true; an empty string otherwise")
    var url: String
}

/// Resolves natural-language address-bar input ("weather in SF") to the
/// matching website using on-device Apple Intelligence. Returns nil when the
/// input should be treated as a regular search query, keeping the fallback
/// path instant and private.
@MainActor
final class SmartAddressService {
    static let shared = SmartAddressService()

    private init() {}

    func resolve(query: String) async -> URL? {
        guard SystemLanguageModel.default.isAvailable else { return nil }
        do {
            let session = LanguageModelSession(instructions: Self.instructions)
            let draft = try await session.respond(
                to: Self.prompt(query: query),
                generating: AddressResolutionDraft.self
            ).content
            guard draft.isDirectSite else { return nil }
            return Self.validatedURL(draft.url)
        } catch {
            return nil
        }
    }

    private static let instructions = """
    You resolve address-bar input into website URLs. Set isDirectSite to true \
    only when the input unambiguously names one specific website or web \
    service and you are confident of its canonical URL. Always use the most \
    well-known official site, never a mirror or a search engine results page. \
    When in doubt, set isDirectSite to false so the input is treated as a \
    search query instead.
    """

    private static func prompt(query: String) -> String {
        "Address bar input: \(query)"
    }

    private static func validatedURL(_ raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.contains(" ") else { return nil }
        guard let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              url.host != nil
        else { return nil }
        return url
    }
}
