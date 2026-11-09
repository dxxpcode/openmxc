import SwiftUI

/// Calm, typography-first rendering of an extracted article. Replaces the web
/// content for the current tab until dismissed; the web view stays alive
/// underneath.
struct ReaderView: View {
    @Environment(BrowserController.self) private var controller
    @Environment(\.colorScheme) private var colorScheme

    let article: ReaderArticle
    let navigation: NavigationManager

    @State private var savedToReadingList = false

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Divider().opacity(0.4)
            ScrollView {
                articleContent
                    .frame(maxWidth: 640)
                    .padding(.horizontal, 40)
                    .padding(.top, 48)
                    .padding(.bottom, 96)
                    .frame(maxWidth: .infinity)
            }
        }
        .background(GlassCanvasBackground())
        .background { escapeHandler }
        .onAppear {
            savedToReadingList = !navigation.isPrivateBrowsing
                && ReadingListStore.shared.items.contains { $0.url == article.url }
        }
    }

    // MARK: - Chrome

    private var topBar: some View {
        HStack(spacing: 12) {
            Button {
                navigation.exitReaderMode()
            } label: {
                Label("Done", systemImage: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(ReaderBarButtonStyle())
            .help("Exit Reader Mode (Esc)")
            .accessibilityLabel("Exit Reader Mode")

            Spacer()

            if !navigation.isPrivateBrowsing {
                Button {
                    ReadingListStore.shared.add(title: article.title, url: article.url)
                    savedToReadingList = true
                } label: {
                    Label(
                        savedToReadingList ? "Saved" : "Reading List",
                        systemImage: savedToReadingList ? "checkmark" : "bookmark"
                    )
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(savedToReadingList ? Color.accentColor : Color.secondary)
                }
                .buttonStyle(ReaderBarButtonStyle())
                .disabled(savedToReadingList)
                .help("Save to Reading List")
                .accessibilityLabel("Save to Reading List")
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 48)
    }

    @ViewBuilder
    private var escapeHandler: some View {
        if !controller.zenMode {
            Button("") { navigation.exitReaderMode() }
                .keyboardShortcut(.escape, modifiers: [])
                .hidden()
        }
    }

    // MARK: - Article

    private var articleContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            metaLine
            titleBlock
            blocksContent
        }
    }

    @ViewBuilder
    private var metaLine: some View {
        let parts = [article.siteName, article.byline].compactMap { $0 }
        if !parts.isEmpty {
            Text(parts.joined(separator: "  ·  "))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .tracking(0.6)
                .padding(.bottom, 14)
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(article.title)
                .font(.system(size: 34, weight: .bold, design: .serif))
                .tracking(-0.4)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            Divider()
                .padding(.top, 8)
        }
        .padding(.bottom, 28)
    }

    private var blocksContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            ForEach(Array(article.blocks.enumerated()), id: \.offset) { _, block in
                blockView(block)
            }
        }
    }

    @ViewBuilder
    private func blockView(_ block: ReaderArticle.Block) -> some View {
        switch block {
        case .heading(let level, let text):
            Text(text)
                .font(.system(size: headingSize(level), weight: .semibold, design: .serif))
                .tracking(-0.2)
                .foregroundStyle(.primary)
                .padding(.top, 10)
                .fixedSize(horizontal: false, vertical: true)

        case .paragraph(let text):
            Text(text)
                .font(.system(size: 18, design: .serif))
                .lineSpacing(7)
                .foregroundStyle(.primary.opacity(0.88))
                .fixedSize(horizontal: false, vertical: true)

        case .quote(let text):
            HStack(alignment: .top, spacing: 14) {
                Rectangle()
                    .fill(Color.secondary.opacity(0.4))
                    .frame(width: 2)
                Text(text)
                    .font(.system(size: 18, design: .serif))
                    .italic()
                    .lineSpacing(6)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 4)

        case .code(let text):
            Text(text)
                .font(.system(size: 14, design: .monospaced))
                .foregroundStyle(.primary.opacity(0.85))
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

        case .list(let items):
            VStack(alignment: .leading, spacing: 8) {
                ForEach(items.indices, id: \.self) { index in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(items[index])
                            .font(.system(size: 18, design: .serif))
                            .lineSpacing(6)
                            .foregroundStyle(.primary.opacity(0.88))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

        case .image(let urlString, let alt):
            AsyncImage(url: URL(string: urlString)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                case .failure:
                    EmptyView()
                default:
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.secondary.opacity(0.08))
                        .frame(height: 120)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
            }
            .accessibilityLabel(alt.isEmpty ? "Image" : alt)
        }
    }

    private func headingSize(_ level: Int) -> CGFloat {
        switch level {
        case 1: return 26
        case 2: return 23
        case 3: return 20
        default: return 18
        }
    }
}

/// Quiet capsule button for the reader top bar, matching the toolbar's calm
/// chrome.
private struct ReaderBarButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 10)
            .frame(height: 28)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.primary.opacity(configuration.isPressed ? 0.14 : (isHovered ? 0.08 : 0)))
            }
            .contentShape(Rectangle())
            .onHover { hovering in
                withAnimation(Motion.quick) { isHovered = hovering }
            }
            .opacity(isEnabled ? 1 : 0.4)
    }
}
