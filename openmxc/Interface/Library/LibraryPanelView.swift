import AppKit
import SwiftUI

/// Right-side library drawer: bookmarks, history, downloads, and reading list
/// in one calm surface. Opened from the toolbar; closes on Esc, scrim tap, or
/// any navigation.
struct LibraryPanelView: View {
    @Environment(BrowserController.self) private var controller

    @State private var section: LibrarySection
    @State private var query = ""
    @FocusState private var searchFocused: Bool

    init(section: LibrarySection) {
        _section = State(initialValue: section)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            sectionTabs
            searchField
            Divider().opacity(0.4)
            content
        }
        .frame(maxHeight: .infinity)
        .background { escapeHandler }
        .onAppear { searchFocused = true }
    }

    // MARK: - Chrome

    private var header: some View {
        HStack {
            Text("Library")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.primary)
            Spacer()
            sectionAction
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
    }

    /// Quiet per-section header action (clear history, clear completed
    /// downloads). Everything else is handled per-row on hover.
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

    private var sectionTabs: some View {
        HStack(spacing: 2) {
            ForEach(LibrarySection.allCases) { item in
                Button {
                    withAnimation(Motion.quick) { section = item }
                } label: {
                    Image(systemName: item.symbol)
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(section == item ? Color.primary : Color.secondary)
                        .frame(width: 34, height: 30)
                        .background {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(section == item ? Color.primary.opacity(0.1) : .clear)
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .help(item.title)
                .accessibilityLabel(item.title)
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 10)
    }

    private var searchField: some View {
        SearchField(
            placeholder: searchPlaceholder,
            text: $query,
            height: 30,
            focus: $searchFocused
        ) {
            searchFocused = false
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
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
            LazyVStack(spacing: 2) {
                switch section {
                case .bookmarks: bookmarksContent
                case .readingList: readingListContent
                case .history: historyContent
                case .downloads: downloadsContent
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 24)
            .animation(Motion.quick, value: query)
            .animation(Motion.quick, value: section)
        }
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
            ForEach(filteredBookmarks) { favorite in
                LibraryRow(
                    title: favorite.title,
                    subtitle: favorite.url.host() ?? favorite.url.absoluteString,
                    symbol: "star.fill",
                    tint: Color.accentColor
                ) {
                    controller.open(favorite.url)
                } actions: {
                    LibraryRowAction(symbol: "trash", help: "Remove Bookmark") {
                        controller.favorites.remove(favorite)
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
            ForEach(filteredReadingList) { item in
                LibraryRow(
                    title: item.title,
                    subtitle: "\(item.url.host() ?? item.url.absoluteString) · \(item.addedAt.formatted(.relative(presentation: .named)))",
                    symbol: "text.bookmark",
                    tint: item.isRead ? nil : Color.accentColor,
                    titleOpacity: item.isRead ? 0.55 : 1
                ) {
                    if !item.isRead { ReadingListStore.shared.setRead(item, isRead: true) }
                    controller.open(item.url)
                } actions: {
                    LibraryRowAction(
                        symbol: item.isRead ? "circle" : "checkmark.circle",
                        help: item.isRead ? "Mark as Unread" : "Mark as Read"
                    ) {
                        ReadingListStore.shared.setRead(item, isRead: !item.isRead)
                    }
                    LibraryRowAction(symbol: "trash", help: "Remove") {
                        ReadingListStore.shared.remove(item)
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
                    .tracking(0.5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10)
                    .padding(.top, 14)
                    .padding(.bottom, 4)
                ForEach(group.entries) { entry in
                    LibraryRow(
                        title: entry.title,
                        subtitle: "\(entry.url.host() ?? entry.url.absoluteString) · \(entry.visitedAt.formatted(date: .omitted, time: .shortened))",
                        symbol: "clock",
                        tint: nil
                    ) {
                        controller.open(entry.url)
                    } actions: {
                        LibraryRowAction(symbol: "trash", help: "Delete Entry") {
                            HistoryStore.shared.delete(entry)
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
            ForEach(filteredDownloads) { item in
                downloadRow(item)
            }
        }
    }

    private func downloadRow(_ item: DownloadItem) -> some View {
        LibraryRow(
            title: item.filename,
            subtitle: downloadSubtitle(item),
            symbol: downloadSymbol(item),
            tint: item.status == .failed ? .red : nil,
            titleOpacity: item.status == .completed ? 0.7 : 1
        ) {
            openDownload(item)
        } actions: {
            if item.status == .completed, let path = item.destinationPath {
                LibraryRowAction(symbol: "folder", help: "Reveal in Finder") {
                    NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
                }
            }
            LibraryRowAction(symbol: "trash", help: "Remove") {
                removeDownload(item)
            }
        } accessory: {
            if item.status == .inProgress {
                downloadProgress(item)
            }
        }
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

    @ViewBuilder
    private func downloadProgress(_ item: DownloadItem) -> some View {
        if let total = item.totalBytes, total > 0 {
            let fraction = min(max(Double(item.bytesReceived) / Double(total), 0), 1)
            ProgressView(value: fraction)
                .progressViewStyle(.linear)
                .frame(width: 56)
                .tint(Color.accentColor)
        } else {
            ProgressView()
                .controlSize(.small)
                .frame(width: 56)
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

// MARK: - Shared row components

/// One quiet library row: leading symbol tile, title + subtitle, hover-reveal
/// actions, optional accessory (e.g. download progress). Actions stay in
/// layout but fade in on hover so rows never jump.
private struct LibraryRow<Actions: View, Accessory: View>: View {
    let title: String
    let subtitle: String
    let symbol: String
    var tint: Color? = nil
    var titleOpacity: Double = 1
    let onTap: () -> Void
    @ViewBuilder var actions: () -> Actions
    @ViewBuilder var accessory: () -> Accessory

    @State private var isHovered = false

    init(
        title: String,
        subtitle: String,
        symbol: String,
        tint: Color? = nil,
        titleOpacity: Double = 1,
        onTap: @escaping () -> Void,
        @ViewBuilder actions: @escaping () -> Actions,
        @ViewBuilder accessory: @escaping () -> Accessory
    ) {
        self.title = title
        self.subtitle = subtitle
        self.symbol = symbol
        self.tint = tint
        self.titleOpacity = titleOpacity
        self.onTap = onTap
        self.actions = actions
        self.accessory = accessory
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(tint ?? Color.secondary)
                .frame(width: 30, height: 30)
                .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary.opacity(titleOpacity))
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            accessory()
            actions()
                .opacity(isHovered ? 1 : 0)
                .allowsHitTesting(isHovered)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isHovered ? Color.primary.opacity(0.06) : .clear)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .onHover { hovering in
            withAnimation(Motion.quick) { isHovered = hovering }
        }
    }
}


extension LibraryRow where Accessory == EmptyView {
    init(
        title: String,
        subtitle: String,
        symbol: String,
        tint: Color? = nil,
        titleOpacity: Double = 1,
        onTap: @escaping () -> Void,
        @ViewBuilder actions: @escaping () -> Actions
    ) {
        self.init(
            title: title,
            subtitle: subtitle,
            symbol: symbol,
            tint: tint,
            titleOpacity: titleOpacity,
            onTap: onTap,
            actions: actions,
            accessory: { EmptyView() }
        )
    }
}

private struct LibraryRowAction: View {
    let symbol: String
    let help: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 24, height: 24)
                .background(Color.primary.opacity(0.06), in: Circle())
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
        VStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)
            Text(message)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
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
