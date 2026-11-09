import AppKit
import SwiftUI

/// Bottom-sheet library: bookmarks, history, downloads, and reading list as
/// calm card grids. Opened from the toolbar; closes on Esc, scrim tap, or any
/// navigation.
struct LibraryPanelView: View {
    @Environment(BrowserController.self) private var controller

    @State private var section: LibrarySection
    @State private var query = ""
    @FocusState private var searchFocused: Bool
    @Namespace private var tabSelection

    init(section: LibrarySection) {
        _section = State(initialValue: section)
    }

    var body: some View {
        VStack(spacing: 0) {
            sectionTabs
            searchField
            content
        }
        .frame(maxHeight: .infinity)
        .background { escapeHandler }
        .onAppear { searchFocused = true }
    }

    // MARK: - Chrome

    private var sectionTabs: some View {
        HStack(spacing: 2) {
            ForEach(LibrarySection.allCases) { item in
                let isSelected = section == item
                Button {
                    withAnimation(Motion.standard) { section = item }
                    query = ""
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: item.symbol)
                            .font(.system(size: 10.5, weight: isSelected ? .semibold : .medium))
                        Text(tabLabel(item))
                            .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                            .lineLimit(1)
                    }
                    .foregroundStyle(isSelected ? Color.primary : Color.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 28)
                    .background {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.primary.opacity(0.12))
                                .matchedGeometryEffect(id: "tabSelection", in: tabSelection)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(item.title)
                .accessibilityLabel(item.title)
            }
        }
        .padding(3)
        .background {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(Color.primary.opacity(0.05))
                .overlay {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
                }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private func tabLabel(_ item: LibrarySection) -> String {
        switch item {
        case .bookmarks: return "Bookmarks"
        case .readingList: return "Reading"
        case .history: return "History"
        case .downloads: return "Downloads"
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            SearchField(
                placeholder: searchPlaceholder,
                text: $query,
                height: 30,
                focus: $searchFocused
            ) {
                searchFocused = false
            }
            sectionAction
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 12)
    }

    /// Quiet section-level action (clear history, clear completed downloads),
    /// sitting beside the search field. Everything else is per-card on hover.
    @ViewBuilder
    private var sectionAction: some View {
        switch section {
        case .history:
            if !filteredHistory.isEmpty {
                Button("Clear") { confirmClearHistory() }
                    .buttonStyle(LibraryTextButtonStyle())
            }
        case .downloads:
            if DownloadStore.shared.items.contains(where: { $0.status == .completed }) {
                Button("Clear Completed") { DownloadStore.shared.clearCompleted() }
                    .buttonStyle(LibraryTextButtonStyle())
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
        ScrollView {
            LazyVStack(spacing: 12) {
                switch section {
                case .bookmarks: bookmarksContent
                case .readingList: readingListContent
                case .history: historyContent
                case .downloads: downloadsContent
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .animation(Motion.quick, value: query)
            .animation(Motion.quick, value: section)
        }
    }

    private var gridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 210, maximum: 320), spacing: 10)]
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
            LazyVGrid(columns: gridColumns, spacing: 10) {
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
            LazyVGrid(columns: gridColumns, spacing: 10) {
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
            ForEach(historyGroups) { group in
                Text(group.title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 6)
                LazyVGrid(columns: gridColumns, spacing: 10) {
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
            LazyVGrid(columns: gridColumns, spacing: 10) {
                ForEach(filteredDownloads) { item in
                    downloadCard(item)
                }
            }
        }
    }

    private func downloadCard(_ item: DownloadItem) -> some View {
        LibraryCard(
            title: item.filename,
            subtitle: downloadSubtitle(item),
            url: nil,
            fallbackSymbol: downloadSymbol(item),
            fallbackTint: item.status == .failed ? .red : (item.status == .completed ? Color.green : nil),
            titleOpacity: item.status == .completed ? 0.7 : 1,
            progress: downloadProgressFraction(item)
        ) {
            openDownload(item)
        } actions: {
            if item.status == .completed, let path = item.destinationPath {
                LibraryCardAction(symbol: "folder", help: "Reveal in Finder") {
                    NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
                }
            }
            LibraryCardAction(symbol: "trash", help: "Remove") {
                removeDownload(item)
            }
        }
    }

    private func downloadProgressFraction(_ item: DownloadItem) -> Double? {
        guard item.status == .inProgress,
              let total = item.totalBytes, total > 0
        else { return nil }
        return min(max(Double(item.bytesReceived) / Double(total), 0), 1)
    }

    private func downloadSubtitle(_ item: DownloadItem) -> String {
        let size = item.fileSize.map { ByteCountFormatter.string(fromByteCount: $0, countStyle: .file) }
        switch item.status {
        case .inProgress:
            return [size, "Downloading"].compactMap { $0 }.joined(separator: " · ")
        case .completed:
            return [size, item.completedAt?.formatted(.relative(presentation: .named))].compactMap { $0 }.joined(separator: " · ")
        case .failed:
            return "Failed"
        case .cancelled:
            return "Cancelled"
        }
    }

    private func downloadSymbol(_ item: DownloadItem) -> String {
        switch item.status {
        case .inProgress: return "arrow.down.circle"
        case .completed: return "checkmark.circle"
        case .failed: return "exclamationmark.circle"
        case .cancelled: return "minus.circle"
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

/// Leading 28pt icon tile: the site's favicon when available, otherwise a
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
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color.primary.opacity(0.06))
            if let icon {
                if colorScheme == .dark {
                    Image(nsImage: icon)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: 15, height: 15)
                        .padding(4)
                        .background(
                            Color.white,
                            in: RoundedRectangle(cornerRadius: 4.5, style: .continuous)
                        )
                } else {
                    Image(nsImage: icon)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: 17, height: 17)
                }
            } else {
                Image(systemName: symbol)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(tint ?? Color.secondary)
            }
        }
        .frame(width: 28, height: 28)
        .onAppear { loadIcon() }
    }

    private func loadIcon() {
        guard let url else { return }
        FaviconService.shared.icon(for: url) { image in
            icon = image
        }
    }
}

/// One calm library card: favicon tile with hover-reveal actions, title and
/// subtitle, optional download progress bar. Hover lifts the card and fades
/// in its actions; layout never shifts.
private struct LibraryCard<Actions: View>: View {
    let title: String
    let subtitle: String
    let url: URL?
    let fallbackSymbol: String
    var fallbackTint: Color? = nil
    var titleOpacity: Double = 1
    var showsUnreadDot: Bool = false
    var progress: Double? = nil
    let onTap: () -> Void
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
        progress: Double? = nil,
        onTap: @escaping () -> Void,
        @ViewBuilder actions: @escaping () -> Actions
    ) {
        self.title = title
        self.subtitle = subtitle
        self.url = url
        self.fallbackSymbol = fallbackSymbol
        self.fallbackTint = fallbackTint
        self.titleOpacity = titleOpacity
        self.showsUnreadDot = showsUnreadDot
        self.progress = progress
        self.onTap = onTap
        self.actions = actions
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                LibraryIcon(url: url, symbol: fallbackSymbol, tint: fallbackTint)
                Spacer(minLength: 4)
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
            if let progress {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
                    .tint(Color.accentColor)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.primary.opacity(isHovered ? 0.07 : 0.045))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.primary.opacity(isHovered ? 0.1 : 0.06), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(isHovered ? 0.06 : 0), radius: 8, y: 2)
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
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 22, height: 22)
                .background(Color.primary.opacity(0.08), in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
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
                .font(.system(size: 20, weight: .light))
                .foregroundStyle(.secondary)
                .frame(width: 52, height: 52)
                .background(Color.primary.opacity(0.05), in: Circle())
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)
            Text(message)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .padding(.horizontal, 24)
    }
}

/// Small quiet text button for section-level actions (Clear, Clear Completed).
private struct LibraryTextButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(isHovered ? Color.primary : Color.secondary)
            .padding(.horizontal, 8)
            .frame(height: 24)
            .background {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.primary.opacity(configuration.isPressed ? 0.14 : (isHovered ? 0.08 : 0)))
            }
            .contentShape(Rectangle())
            .onHover { hovering in
                withAnimation(Motion.quick) { isHovered = hovering }
            }
            .opacity(isEnabled ? 1 : 0.4)
    }
}
