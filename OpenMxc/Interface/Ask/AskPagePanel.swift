import SwiftUI

/// Floating "Ask this page" panel powered by on-device Apple Intelligence.
/// Slides up from the bottom of the window; answers stream in as they generate.
struct AskPagePanel: View {
    @Environment(BrowserController.self) private var controller
    @Environment(\.colorScheme) private var colorScheme

    let onClose: () -> Void

    @State private var service = PageAIService.shared
    @State private var question = ""
    @FocusState private var inputFocused: Bool

    private static let suggestions = [
        "Summarize this page",
        "What is this page about?",
        "Key takeaways",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            content
            inputRow
        }
        .padding(16)
        .frame(width: 560)
        .background { panelBackground }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(borderColor, lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.5 : 0.18), radius: 24, y: 8)
        .onAppear {
            service.reset()
            inputFocused = true
        }
        .onExitCommand { onClose() }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.accentColor)
            Text("Ask this page")
                .font(.system(size: 13, weight: .medium))
            if let host = controller.selectedNavigation?.currentURL?.host() {
                Text(host)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Button {
                onClose()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
                    .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Close")
            .accessibilityLabel("Close")
        }
    }

    @ViewBuilder
    private var content: some View {
        switch service.state {
        case .idle:
            if service.isAvailable {
                suggestionChips
            } else {
                unavailableMessage
            }
        case .thinking:
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text("Reading the page…")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
        case .answering(let answer):
            ScrollView {
                Text(answer)
                    .font(.callout)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 220)
        case .failed(let message):
            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
                .padding(.vertical, 8)
        }
    }

    private var suggestionChips: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Self.suggestions, id: \.self) { suggestion in
                Button {
                    question = suggestion
                    submit()
                } label: {
                    Text(suggestion)
                        .font(.callout)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.primary.opacity(0.05), in: Capsule())
                        .overlay {
                            Capsule().strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }

    private var unavailableMessage: some View {
        Text("Apple Intelligence is not available on this device, so on-device page Q&A can't run here.")
            .font(.callout)
            .foregroundStyle(.secondary)
            .padding(.vertical, 8)
    }

    private var inputRow: some View {
        SearchField(
            placeholder: "Ask about this page…",
            text: $question,
            height: 36,
            icon: "sparkles",
            focus: $inputFocused
        ) {
            submit()
        }
        .disabled(!service.isAvailable)
    }

    private func submit() {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        question = ""
        Task { await performAsk(trimmed) }
    }

    private func performAsk(_ question: String) async {
        guard let navigation = controller.selectedNavigation else {
            service.fail("No page is open.")
            return
        }
        let pageText = await navigation.pageText() ?? ""
        let pageTitle = navigation.pageTitle.isEmpty
            ? (navigation.currentURL?.host() ?? "Untitled page")
            : navigation.pageTitle
        await service.ask(
            question: question,
            pageTitle: pageTitle,
            pageURL: navigation.currentURL,
            pageText: pageText
        )
    }

    /// Frosted panel: vibrancy material with a theme tint so page content
    /// softly bleeds through the rounded card.
    private var panelBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.regularMaterial)
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorScheme == .dark ? Color.black.opacity(0.35) : Color.white.opacity(0.3))
        }
    }

    private var borderColor: Color {
        colorScheme == .dark ? Color.primary.opacity(0.16) : Color(nsColor: .separatorColor)
    }
}
