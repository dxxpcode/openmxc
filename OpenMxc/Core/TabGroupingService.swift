import Foundation
import FoundationModels

/// Draft shape the on-device model fills in when grouping tabs.
@Generable
struct TabGroupsDraft {
    @Guide(description: "Topic groups covering the tabs. 2 to 6 groups.")
    var groups: [TabGroupDraft]
}

@Generable
struct TabGroupDraft {
    @Guide(description: "Short topic name, e.g. 'News', 'Shopping', 'Docs', 'Other'")
    var name: String

    @Guide(description: "1-based indices of the tabs in this group, from the provided tab list")
    var tabIndices: [Int]
}

/// Groups a window's tabs by topic using on-device Apple Intelligence.
/// Only tab titles and hosts are sent to the model — never page content.
@Observable
@MainActor
final class TabGroupingService {
    struct TabGroup: Identifiable {
        let id = UUID()
        let name: String
        let tabs: [TabModel]
    }

    enum State {
        case idle
        case thinking
        case grouped([TabGroup])
        case failed(String)
    }

    private(set) var state: State = .idle

    var isAvailable: Bool {
        SystemLanguageModel.default.isAvailable
    }

    func reset() {
        state = .idle
    }

    func group(tabs: [TabModel]) async {
        state = .thinking
        guard tabs.count > 1 else {
            state = .grouped([])
            return
        }
        do {
            let session = LanguageModelSession(instructions: Self.instructions)
            let draft = try await session.respond(to: Self.prompt(tabs: tabs), generating: TabGroupsDraft.self).content
            state = .grouped(makeGroups(from: draft, tabs: tabs))
        } catch {
            state = .failed(Self.message(for: error))
        }
    }

    private static let instructions = """
    You organize browser tabs into topic groups. Use only the provided tab \
    list. Every tab index must appear in exactly one group. Use short, \
    specific group names of one to three words. Put tabs that share no clear \
    topic into a group named 'Other'. Never invent tab indices.
    """

    private static func prompt(tabs: [TabModel]) -> String {
        let list = tabs.enumerated().map { index, tab in
            let host = tab.navigation.currentURL?.host() ?? tab.navigation.lastLoadedURL?.host() ?? ""
            let title = tab.displayTitle
            let label = title.isEmpty ? host : title
            return "\(index + 1). \(label) — \(host)"
        }.joined(separator: "\n")
        return """
        Tabs:
        \(list)

        Group these \(tabs.count) tabs by topic.
        """
    }

    private func makeGroups(from draft: TabGroupsDraft, tabs: [TabModel]) -> [TabGroup] {
        var assigned = Set<UUID>()
        var groups: [TabGroup] = []

        for entry in draft.groups {
            let members = entry.tabIndices.compactMap { index -> TabModel? in
                guard (1...tabs.count).contains(index) else { return nil }
                let tab = tabs[index - 1]
                guard !assigned.contains(tab.id) else { return nil }
                assigned.insert(tab.id)
                return tab
            }
            guard !members.isEmpty else { continue }
            let name = entry.name.trimmingCharacters(in: .whitespacesAndNewlines)
            groups.append(TabGroup(name: name.isEmpty ? "Other" : name, tabs: members))
        }

        let rest = tabs.filter { !assigned.contains($0.id) }
        if !rest.isEmpty {
            if groups.isEmpty {
                groups.append(TabGroup(name: "Tabs", tabs: rest))
            } else {
                groups.append(TabGroup(name: "Other", tabs: rest))
            }
        }
        return groups
    }

    private static func message(for error: Error) -> String {
        guard let error = error as? LanguageModelSession.GenerationError else {
            return "Something went wrong. Try again."
        }
        switch error {
        case .exceededContextWindowSize:
            return "Too many tabs to group at once."
        case .assetsUnavailable:
            return "Apple Intelligence is not available on this device."
        case .guardrailViolation, .refusal:
            return "The assistant declined to group these tabs."
        case .rateLimited:
            return "Apple Intelligence is busy. Try again in a moment."
        default:
            return "Something went wrong. Try again."
        }
    }
}
