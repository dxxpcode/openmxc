import AppKit
import SwiftUI

/// Library content shown inside the bottom dock: bookmarks, reading list,
/// history, or downloads for the selected section.
struct DockLibraryView: View {
    let section: LibrarySection
    let query: String
    let open: (URL) -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            list
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text(section.title)
                .font(.system(size: 13, weight: .semibold))
            Spacer()
            clearButton
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var clearButton: some View {
        switch section {
        case .history:
            if !HistoryStore.shared.entries.isEmpty {
                Button("Clear History") { HistoryStore.shared.clearAll() }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        case .downloads:
            if DownloadStore.shared.items.contains(where: { $0.status == .completed || $0.status == .failed || $0.status == .cancelled }) {
                Button("Clear Completed") { DownloadStore.shared.clearCompleted() }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private var list: some View {
        switch section {
        case .bookmarks: BookmarksList(query: query, open: open)
        case .readingList: ReadingList(query: query, open: open)
        case .history: HistoryList(query: query, open: open)
        case .downloads: DownloadsList(query: query)
        }
    }
}

// MARK: - Sections

private struct BookmarksList: View {
    let query: String
    let open: (URL) -> Void
    private var store: BookmarkStore { .shared }

    var body: some View {
        let items = store.allMatching(query)
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        PanelList(isEmpty: items.isEmpty, emptyText: query.isEmpty ? "No bookmarks yet" : "No results") {
            ForEach(items) { bookmark in
                DockLibraryRow(title: bookmark.title, url: bookmark.url) {
                    open(bookmark.url)
                } onDelete: {
                    store.deleteBookmark(bookmark)
                }
            }
        }
    }
}

private struct ReadingList: View {
    let query: String
    let open: (URL) -> Void
    private var store: ReadingListStore { .shared }

    var body: some View {
        let items = store.search(query)
        PanelList(isEmpty: items.isEmpty, emptyText: query.isEmpty ? "Your reading list is empty" : "No results") {
            ForEach(items) { item in
                DockLibraryRow(title: item.title, url: item.url, isDimmed: item.isRead) {
                    store.setRead(item, isRead: true)
                    open(item.url)
                } onDelete: {
                    store.remove(item)
                }
            }
        }
    }
}

private struct HistoryList: View {
    let query: String
    let open: (URL) -> Void
    private var store: HistoryStore { .shared }

    var body: some View {
        let groups = Self.group(store.search(query))
        PanelList(isEmpty: groups.isEmpty, emptyText: query.isEmpty ? "No history yet" : "No results") {
            ForEach(groups, id: \.title) { group in
                DockSectionHeader(title: group.title)
                ForEach(group.entries) { entry in
                    DockLibraryRow(title: entry.title, url: entry.url) {
                        open(entry.url)
                    } onDelete: {
                        store.delete(entry)
                    }
                }
            }
        }
    }

    private static func group(_ entries: [HistoryEntry]) -> [(title: String, entries: [HistoryEntry])] {
        let calendar = Calendar.current
        var result: [(title: String, entries: [HistoryEntry])] = []
        for entry in entries {
            let title: String
            if calendar.isDateInToday(entry.visitedAt) {
                title = "Today"
            } else if calendar.isDateInYesterday(entry.visitedAt) {
                title = "Yesterday"
            } else {
                title = entry.visitedAt.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
            }
            if result.last?.title == title {
                result[result.count - 1].entries.append(entry)
            } else {
                result.append((title, [entry]))
            }
        }
        return result
    }
}

private struct DownloadsList: View {
    let query: String

    var body: some View {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        let items = trimmed.isEmpty
            ? DownloadStore.shared.items
            : DownloadStore.shared.items.filter { $0.filename.localizedCaseInsensitiveContains(trimmed) }
        PanelList(isEmpty: items.isEmpty, emptyText: query.isEmpty ? "No downloads yet" : "No results") {
            ForEach(items) { item in
                DockDownloadRow(item: item) {
                    DownloadStore.shared.remove(item)
                }
            }
        }
    }
}

// MARK: - Building blocks

private struct PanelList<Content: View>: View {
    let isEmpty: Bool
    let emptyText: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        if isEmpty {
            Text(emptyText)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 1) {
                    content()
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
            }
        }
    }
}

private struct DockSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.top, 10)
            .padding(.bottom, 3)
    }
}

private struct DockLibraryRow: View {
    let title: String
    let url: URL
    var isDimmed = false
    let action: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false
    @State private var favicon: NSImage?

    var body: some View {
        HStack(spacing: 11) {
            FaviconTile(image: favicon, size: 24)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 13))
                    .lineLimit(1)
                Text(url.host() ?? url.absoluteString)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .opacity(isDimmed ? 0.5 : 1)

            Spacer(minLength: 6)

            if isHovered {
                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 20, height: 20)
                        .background(Color.primary.opacity(0.08), in: Circle())
                }
                .buttonStyle(.plain)
                .help("Remove")
            }
        }
        .padding(.horizontal, 9)
        .frame(height: 44)
        .background {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Color.primary.opacity(isHovered ? 0.06 : 0))
        }
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onTapGesture(perform: action)
        .onAppear {
            FaviconService.shared.icon(for: url) { image in
                favicon = image
            }
        }
    }
}

private struct DockDownloadRow: View {
    let item: DownloadItem
    let onRemove: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 11) {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.primary.opacity(0.05))
                Image(systemName: symbol)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(item.status == .failed ? Color.red : .secondary)
            }
            .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.filename)
                    .font(.system(size: 13))
                    .lineLimit(1)
                    .truncationMode(.middle)
                if item.status == .inProgress {
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                        .controlSize(.mini)
                } else {
                    Text(detail)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 6)

            if isHovered {
                Button {
                    if item.status == .inProgress {
                        DownloadCoordinator.cancel(item)
                    } else {
                        onRemove()
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 20, height: 20)
                        .background(Color.primary.opacity(0.08), in: Circle())
                }
                .buttonStyle(.plain)
                .help(item.status == .inProgress ? "Cancel" : "Remove")
            }
        }
        .padding(.horizontal, 9)
        .frame(height: 46)
        .background {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Color.primary.opacity(isHovered ? 0.06 : 0))
        }
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onTapGesture {
            guard item.status == .completed, let path = item.destinationPath else { return }
            NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
        }
        .help(item.status == .completed ? "Show in Finder" : "")
    }

    private var symbol: String {
        switch item.status {
        case .inProgress: return "arrow.down"
        case .completed: return "doc"
        case .failed: return "exclamationmark"
        case .cancelled: return "minus"
        }
    }

    private var progress: Double {
        guard let total = item.totalBytes, total > 0 else { return 0 }
        return Double(item.bytesReceived) / Double(total)
    }

    private var detail: String {
        switch item.status {
        case .inProgress: return ""
        case .completed:
            if let size = item.fileSize {
                return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
            }
            return "Completed"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        }
    }
}
