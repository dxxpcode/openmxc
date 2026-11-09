import AppKit
import SwiftUI

/// Start-page takeover library: a full-window canvas with macOS 26 glass
/// components. Sections as pages behind a glass picker, content as glass
/// cards. Opened from the toolbar; closes on Esc, close button, or navigation.
struct LibraryCanvasView: View {
    @Environment(BrowserController.self) private var controller

    @State private var section: LibrarySection
    @State private var query = ""
    @FocusState private var searchFocused: Bool

    init(section: LibrarySection) {
        _section = State(initialValue: section)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                    .padding(.top, 72)
                sectionPicker
                    .padding(.top, 22)
                searchField
                    .padding(.top, 18)
                content
                    .padding(.top, 24)
            }
            .frame(maxWidth: 780)
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
            .frame(maxWidth: .infinity)
        }
        .background { escapeHandler }
        .onAppear { searchFocused = true }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Library")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.primary)
            Spacer()
            Button {
                controller.closeLibrary()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.glass)
            .help("Close Library")
            .accessibilityLabel("Close Library")
        }
    }

    // MARK: - Section picker (glass)

    private var sectionPicker: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(LibrarySection.allCases) { item in
                    sectionButton(item)
                }
            }
        }
    }

    @ViewBuilder
    private func sectionButton(_ item: LibrarySection) -> some View {
        let isSelected = section == item
        let button = Button {
            withAnimation(Motion.standard) { section = item }
            query = ""
        } label: {
            HStack(spacing: 6) {
                Image(systemName: item.symbol)
                    .font(.system(size: 11, weight: .semibold))
                Text(tabLabel(item))
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? Color.primary : Color.secondary)
            .padding(.horizontal, 14)
            .frame(height: 30)
        }
        .help(item.title)
        .accessibilityLabel(item.title)
        if isSelected {
            button.buttonStyle(.glassProminent)
        } else {
            button.buttonStyle(.glass)
        }
    }

    private func tabLabel(_ item: LibrarySection) -> String {
        switch item {
        case .bookmarks: return "Bookmarks"
        case .readingList: return "Reading"
        case .history: return "History"
        case .downloads: return "Downloads"
        }
    }

    // MARK: - Search

    private var searchField: some View {
        HStack(spacing: 12) {
            SearchField(
                placeholder: searchPlaceholder,
                text: $query,
                height: 34,
                focus: $searchFocused
            ) {
                searchFocused = false
            }
            sectionAction
        }
        .frame(maxWidth: 560)
    }

    /// Quiet section-level action beside the search (clear history, clear
    /// completed downloads). Everything else is per-card on hover.
    @ViewBuilder
    private var sectionAction: some View {
        switch section {
        case .history:
            if !filteredHistory.isEmpty {
                Button("Clear History") { confirmClearHistory() }
                    .buttonStyle(.glass)
            }
        case .downloads:
            if DownloadStore.shared.items.contains(where: { $0.status == .completed }) {
                Button("Clear Completed") { DownloadStore.shared.clearCompleted() }
                    .buttonStyle(.glass)
            }
        default:
            EmptyView()
        }
    }

    private var searchPlaceholder: String {
        switch section {
        case .bookmarks: return "Search bookmarks"
        case .readingList: return "Search reading list"
        case .history: return "Search history"
        case .downloads: return "Search downloads"
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        VStack(spacing: 20) {
            switch section {
            case .bookmarks: bookmarksContent
            case .readingList: readingListContent
            case .history: historyContent
            case .downloads: downloadsContent
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(Motion.quick, value: query)
        .animation(Motion.quick, value: section)
    }

    private var gridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 220, maximum: 300), spacing: 14)]
    }

    // MARK: - Bookmarks (favorites)

    private var filteredBookmarks: [Favorite] {
        let favorites = controller.favorites.favorites
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return favorites }
        return favorites.filter {
            $0.title.localizedCaseInsensitiveContains(trimmed)
                || $0.url.host()?.localizedCaseInsensitiveContains(trimmed) == true
        }
    }

    @ViewBuilder
    private var bookmarksContent: some View {
        if filteredBookmarks.isEmpty {
            LibraryEmptyState(
                symbol: "star",
                title: query.isEmpty ? "No bookmarks yet" : "No matches",
                message: query.isEmpty ? "Star a page from the toolbar to keep it here." : "Try a different search."
            )
        } else {
            GlassEffectContainer(spacing: 14) {
                LazyVGrid(columns: gridColumns, spacing: 14) {
                    ForEach(filteredBookmarks) { favorite in
                        LibraryCard(
                            title: favorite.title,
                            subtitle: favorite.url.host() ?? favorite.url.absoluteString,
                            url: favorite.url,
                            fallbackSymbol: "star.fill",
                            fallbackTint: Color.accentColor
                        ) {
                            controller.open(favorite.url)
                        } actions: {
                            LibraryCardAction(symbol: "trash", help: "Remove Bookmark") {
                                controller.favorites.remove(favorite)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Reading list

    private var filteredReadingList: [ReadingListItem] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return ReadingListStore.shared.items }
        return ReadingListStore.shared.search(trimmed)
    }

    @ViewBuilder
    private var readingListContent: some View {
        if filteredReadingList.isEmpty {
            LibraryEmptyState(
                symbol: "text.bookmark",
                title: query.isEmpty ? "Reading list is empty" : "No matches",
                message: query.isEmpty ? "Save articles from Reader Mode to read later." : "Try a different search."
            )
        } else {
            GlassEffectContainer(spacing: 14) {
                LazyVGrid(columns: gridColumns, spacing: 14) {
                    ForEach(filteredReadingList) { item in
                        LibraryCard(
                            title: item.title,
                            subtitle: "\(item.url.host() ?? item.url.absoluteString) · \(item.addedAt.formatted(.relative(presentation: .named)))",
                            url: item.url,
                            fallbackSymbol: "text.bookmark",
                            fallbackTint: item.isRead ? nil : Color.accentColor,
                            titleOpacity: item.isRead ? 0.55 : 1,
                            showsUnreadDot: !item.isRead
                        ) {
                            if !item.isRead { ReadingListStore.shared.setRead(item, isRead: true) }
                            controller.open(item.url)
                        } actions: {
                            LibraryCardAction(
                                symbol: item.isRead ? "circle" : "checkmark.circle",
                                help: item.isRead ? "Mark as Unread" : "Mark as Read"
                            ) {
                                ReadingListStore.shared.setRead(item, isRead: !item.isRead)
                            }
                            LibraryCardAction(symbol: "trash", help: "Remove") {
                                ReadingListStore.shared.remove(item)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - History

    private struct HistoryGroup: Identifiable {
        let id: String
        let title: String
        let entries: [HistoryEntry]
    }

    private var filteredHistory: [HistoryEntry] {
        HistoryStore.shared.search(query)
    }

    private var historyGroups: [HistoryGroup] {
        let calendar = Calendar.current
        var groups: [(title: String, entries: [HistoryEntry])] = []
        for entry in filteredHistory {
            let title: String
            if calendar.isDateInToday(entry.visitedAt) {
                title = "Today"
            } else if calendar.isDateInYesterday(entry.visitedAt) {
                title = "Yesterday"
            } else {
                title = entry.visitedAt.formatted(date: .abbreviated, time: .omitted)
            }
            if let last = groups.last, last.title == title {
                groups[groups.count - 1].entries.append(entry)
            } else {
                groups.append((title, [entry]))
            }
        }
        return groups.map { HistoryGroup(id: $0.title, title: $0.title, entries: $0.entries) }
    }

    @ViewBuilder
    private var historyContent: some View {
        if filteredHistory.isEmpty {
            LibraryEmptyState(
                symbol: "clock",
                title: query.isEmpty ? "No history yet" : "No matches",
                message: query.isEmpty ? "Pages you visit will show up here." : "Try a different search."
            )
        } else {
            VStack(spacing: 20) {
                ForEach(historyGroups) { group in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(group.title)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.6)
                        GlassEffectContainer(spacing: 14) {
                            LazyVGrid(columns: gridColumns, spacing: 14) {
                                ForEach(group.entries) { entry in
                                    LibraryCard(
                                        title: entry.title,
                                        subtitle: "\(entry.url.host() ?? entry.url.absoluteString) · \(entry.visitedAt.formatted(date: .omitted, time: .shortened))",
                                        url: entry.url,
                                        fallbackSymbol: "globe",
                                        fallbackTint: nil
                                    ) {
                                        controller.open(entry.url)
                                    } actions: {
                                        LibraryCardAction(symbol: "trash", help: "Delete Entry") {
                                            HistoryStore.shared.delete(entry)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    // MARK: - Downloads

    private var filteredDownloads: [DownloadItem] {
        let items = DownloadStore.shared.items
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return items }
        return items.filter {
            $0.filename.localizedCaseInsensitiveContains(trimmed)
                || $0.url.absoluteString.localizedCaseInsensitiveContains(trimmed)
        }
    }

    @ViewBuilder
    private var downloadsContent: some View {
        if filteredDownloads.isEmpty {
            LibraryEmptyState(
                symbol: "arrow.down.circle",
                title: query.isEmpty ? "No downloads yet" : "No matches",
                message: query.isEmpty ? "Downloads will appear here." : "Try a different search."
            )
        } else {
            GlassEffectContainer(spacing: 14) {
                LazyVGrid(columns: gridColumns, spacing: 14) {
                    ForEach(filteredDownloads) { item in
                        downloadCard(item)
                    }
                }
            }
        }
    }

    private func downloadCard(_ item: DownloadItem) -> some View {
        LibraryCard(
            title: item.filename,
            subtitle: downloadSubtitle(item),
            url: nil,
            fallbackSymbol: "doc",
            titleOpacity: item.status == .completed ? 0.7 : 1,
            onTap: { openDownload(item) },
            accessory: { downloadAccessory(item) },
            actions: {
                if item.status == .completed, let path = item.destinationPath {
                    LibraryCardAction(symbol: "folder", help: "Reveal in Finder") {
                        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
                    }
                }
                LibraryCardAction(symbol: "trash", help: "Remove") {
                    removeDownload(item)
                }
            }
        )
    }

    @ViewBuilder
    private func downloadAccessory(_ item: DownloadItem) -> some View {
        switch item.status {
        case .inProgress:
            if let total = item.totalBytes, total > 0 {
                let fraction = min(max(Double(item.bytesReceived) / Double(total), 0), 1)
                ProgressView(value: fraction)
                    .progressViewStyle(.circular)
                    .controlSize(.small)
                    .tint(Color.accentColor)
            } else {
                ProgressView()
                    .controlSize(.small)
            }
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.green)
        case .failed:
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.red)
        case .cancelled:
            Image(systemName: "minus.circle")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }

    private func downloadSubtitle(_ item: DownloadItem) -> String {
        let size = item.fileSize.map { ByteCountFormatter.string(fromByteCount: $0, countStyle: .file) }
        switch item.status {
        case .inProgress:
            if let total = item.totalBytes, total > 0 {
                let percent = Int((Double(item.bytesReceived) / Double(total)) * 100)
                return [size, "\(percent)%"].compactMap { $0 }.joined(separator: " · ")
            }
            return [size, "Downloading"].compactMap { $0 }.joined(separator: " · ")
        case .completed:
            return [size, item.completedAt?.formatted(.relative(presentation: .named))].compactMap { $0 }.joined(separator: " · ")
        case .failed:
            return "Failed"
        case .cancelled:
            return "Cancelled"
        }
    }

    private func openDownload(_ item: DownloadItem) {
        guard item.status == .completed,
              let path = item.destinationPath,
              FileManager.default.fileExists(atPath: path)
        else { return }
        NSWorkspace.shared.open(URL(fileURLWithPath: path))
    }

    private func removeDownload(_ item: DownloadItem) {
        if let path = item.destinationPath {
            try? FileManager.default.removeItem(atPath: path)
        }
        DownloadStore.shared.remove(item)
    }

    // MARK: - Helpers

    private func confirmClearHistory() {
        let alert = NSAlert()
        alert.messageText = "Clear all history?"
        alert.informativeText = "This removes every page you've visited. This can't be undone."
        alert.addButton(withTitle: "Clear History")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn {
            HistoryStore.shared.clearAll()
        }
    }

    @ViewBuilder
    private var escapeHandler: some View {
        Button("") { controller.closeLibrary() }
            .keyboardShortcut(.escape, modifiers: [])
            .hidden()
    }
}

// MARK: - Card components

/// Leading 40pt favicon tile: the site's favicon when available, otherwise a
/// section symbol. Dark mode gives icons a light backing plate, like
/// Safari's top sites, so dark favicons stay visible.
private struct LibraryIcon: View {
    let url: URL?
    let symbol: String
    let tint: Color?

    @Environment(\.colorScheme) private var colorScheme
    @State private var icon: NSImage?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(Color.primary.opacity(0.06))
            if let icon {
                if colorScheme == .dark {
                    Image(nsImage: icon)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .padding(6)
                        .background(
                            Color.white,
                            in: RoundedRectangle(cornerRadius: 7, style: .continuous)
                        )
                } else {
                    Image(nsImage: icon)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
            } else {
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(tint ?? Color.secondary)
            }
        }
        .frame(width: 40, height: 40)
        .onAppear { loadIcon() }
    }

    private func loadIcon() {
        guard let url else { return }
        FaviconService.shared.icon(for: url) { image in
            icon = image
        }
    }
}

/// One glass library card: favicon tile with hover-reveal actions, title and
/// subtitle, optional trailing accessory (download ring/status). Built on
/// macOS 26 `glassEffect` with interactive response.
private struct LibraryCard<Actions: View, Accessory: View>: View {
    let title: String
    let subtitle: String
    let url: URL?
    let fallbackSymbol: String
    var fallbackTint: Color? = nil
    var titleOpacity: Double = 1
    var showsUnreadDot: Bool = false
    let onTap: () -> Void
    @ViewBuilder var accessory: () -> Accessory
    @ViewBuilder var actions: () -> Actions

    @State private var isHovered = false

    init(
        title: String,
        subtitle: String,
        url: URL?,
        fallbackSymbol: String,
        fallbackTint: Color? = nil,
        titleOpacity: Double = 1,
        showsUnreadDot: Bool = false,
        onTap: @escaping () -> Void,
        @ViewBuilder accessory: @escaping () -> Accessory = { EmptyView() },
        @ViewBuilder actions: @escaping () -> Actions
    ) {
        self.title = title
        self.subtitle = subtitle
        self.url = url
        self.fallbackSymbol = fallbackSymbol
        self.fallbackTint = fallbackTint
        self.titleOpacity = titleOpacity
        self.showsUnreadDot = showsUnreadDot
        self.onTap = onTap
        self.accessory = accessory
        self.actions = actions
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                LibraryIcon(url: url, symbol: fallbackSymbol, tint: fallbackTint)
                Spacer(minLength: 4)
                accessory()
                actions()
                    .opacity(isHovered ? 1 : 0)
                    .allowsHitTesting(isHovered)
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    if showsUnreadDot {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 5, height: 5)
                    }
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.primary.opacity(titleOpacity))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 18, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .onHover { hovering in
            withAnimation(Motion.quick) { isHovered = hovering }
        }
    }
}

private struct LibraryCardAction: View {
    let symbol: String
    let help: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 24, height: 24)
        }
        .buttonStyle(.glass)
        .help(help)
        .accessibilityLabel(help)
    }
}

private struct LibraryEmptyState: View {
    let symbol: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(.secondary)
                .frame(width: 56, height: 56)
                .glassEffect(.regular, in: .circle)
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)
            Text(message)
                .font(.system(size: 12.5))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 56)
        .padding(.horizontal, 24)
    }
}
