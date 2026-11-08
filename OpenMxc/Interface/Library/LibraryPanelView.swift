import AppKit
import SwiftUI

struct LibraryPanelView: View {
    @Environment(BrowserController.self) private var controller

    var body: some View {
        VStack(spacing: 0) {
            header
            sectionPicker
            Divider()
            content
        }
        .frame(width: 340)
        .frame(maxHeight: .infinity)
        .background(Color(nsColor: .controlBackgroundColor))
        .overlay(alignment: .leading) {
            Divider()
        }
    }

    private var header: some View {
        HStack {
            Text("Library")
                .font(.headline)
            Spacer()
            Button {
                controller.showLibraryPanel = false
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.borderless)
            .help("Close (⌘⌥L)")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var sectionPicker: some View {
        HStack(spacing: 2) {
            ForEach(LibrarySection.allCases) { section in
                Button {
                    controller.libraryPanelSection = section
                } label: {
                    Image(systemName: section.symbol)
                        .font(.system(size: 12))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background {
                            if controller.libraryPanelSection == section {
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(Color.accentColor.opacity(0.16))
                            }
                        }
                }
                .buttonStyle(.plain)
                .foregroundStyle(controller.libraryPanelSection == section ? Color.accentColor : .secondary)
                .help(section.title)
            }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 6)
    }

    @ViewBuilder
    private var content: some View {
        switch controller.libraryPanelSection {
        case .bookmarks:
            BookmarksPanel()
        case .readingList:
            ReadingListPanel()
        case .history:
            HistoryPanel()
        case .downloads:
            DownloadsPanel()
        }
    }
}

private struct BookmarksPanel: View {
    @Environment(BrowserController.self) private var controller
    private var store: BookmarkStore { .shared }

    var body: some View {
        list {
            ForEach(store.bookmarks.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }) { bookmark in
                LibraryRow(
                    title: bookmark.title,
                    subtitle: bookmark.url.host() ?? bookmark.url.absoluteString
                ) {
                    controller.open(url: bookmark.url)
                    controller.showLibraryPanel = false
                } onDelete: {
                    store.deleteBookmark(bookmark)
                }
            }
        }
    }

    private func list<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        Group {
            if store.bookmarks.isEmpty {
                EmptyPanelState(symbol: "bookmark", text: "No bookmarks yet.")
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        content()
                    }
                    .padding(8)
                }
            }
        }
    }
}

private struct ReadingListPanel: View {
    @Environment(BrowserController.self) private var controller
    private var store: ReadingListStore { .shared }

    var body: some View {
        Group {
            if store.items.isEmpty {
                EmptyPanelState(symbol: "text.bookmark", text: "Reading list is empty.")
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(store.items) { item in
                            HStack(spacing: 8) {
                                Button {
                                    store.setRead(item, isRead: !item.isRead)
                                } label: {
                                    Image(systemName: item.isRead ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(item.isRead ? Color.accentColor : .secondary)
                                }
                                .buttonStyle(.plain)

                                LibraryRow(
                                    title: item.title,
                                    subtitle: item.url.host() ?? item.url.absoluteString
                                ) {
                                    controller.open(url: item.url)
                                    controller.showLibraryPanel = false
                                } onDelete: {
                                    store.remove(item)
                                }
                            }
                        }
                    }
                    .padding(8)
                }
            }
        }
    }
}

private struct HistoryPanel: View {
    @Environment(BrowserController.self) private var controller
    private var store: HistoryStore { .shared }

    var body: some View {
        Group {
            if store.entries.isEmpty {
                EmptyPanelState(symbol: "clock", text: "No history yet.")
            } else {
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        Button("Clear History") {
                            store.clearAll()
                        }
                        .font(.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)

                    ScrollView {
                        LazyVStack(spacing: 2) {
                            ForEach(store.entries) { entry in
                                LibraryRow(
                                    title: entry.title,
                                    subtitle: entry.url.host() ?? entry.url.absoluteString
                                ) {
                                    controller.open(url: entry.url)
                                    controller.showLibraryPanel = false
                                } onDelete: {
                                    store.delete(entry)
                                }
                            }
                        }
                        .padding(8)
                    }
                }
            }
        }
    }
}

private struct DownloadsPanel: View {
    private var store: DownloadStore { .shared }

    var body: some View {
        Group {
            if store.items.isEmpty {
                EmptyPanelState(symbol: "arrow.down.circle", text: "No downloads yet.")
            } else {
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        Button("Clear Completed") {
                            store.clearCompleted()
                        }
                        .font(.caption)
                        .disabled(!store.items.contains { $0.status != .inProgress })
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)

                    ScrollView {
                        LazyVStack(spacing: 2) {
                            ForEach(store.items) { item in
                                downloadRow(item)
                            }
                        }
                        .padding(8)
                    }
                }
            }
        }
    }

    private func downloadRow(_ item: DownloadItem) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon(for: item.status))
                .font(.caption)
                .foregroundStyle(color(for: item.status))
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.filename)
                    .font(.callout)
                    .lineLimit(1)
                    .truncationMode(.tail)
                if item.status == .inProgress {
                    ProgressView(value: progress(for: item))
                        .frame(width: 120)
                } else {
                    Text(statusText(for: item))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 4)

            if item.status == .completed, let path = item.destinationPath {
                Button {
                    NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
                } label: {
                    Image(systemName: "folder")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Reveal in Finder")
            }

            Button {
                store.remove(item)
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2.weight(.semibold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Remove")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        }
        .contextMenu {
            if item.status == .completed, let path = item.destinationPath {
                Button("Open") {
                    NSWorkspace.shared.open(URL(fileURLWithPath: path))
                }
                Button("Reveal in Finder") {
                    NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
                }
            }
            if item.status == .inProgress {
                Button("Cancel Download") {
                    DownloadCoordinator.cancel(item)
                }
            }
        }
    }

    private func progress(for item: DownloadItem) -> Double {
        guard let total = item.totalBytes, total > 0 else { return 0 }
        return Double(item.bytesReceived) / Double(total)
    }

    private func icon(for status: DownloadStatus) -> String {
        switch status {
        case .inProgress: return "arrow.down.circle"
        case .completed: return "checkmark.circle"
        case .failed: return "exclamationmark.circle"
        case .cancelled: return "minus.circle"
        }
    }

    private func color(for status: DownloadStatus) -> Color {
        switch status {
        case .inProgress: return .accentColor
        case .completed: return .green
        case .failed: return .red
        case .cancelled: return .secondary
        }
    }

    private func statusText(for item: DownloadItem) -> String {
        switch item.status {
        case .inProgress: return "Downloading…"
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        }
    }
}

private struct LibraryRow: View {
    let title: String
    let subtitle: String
    let action: () -> Void
    let onDelete: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.callout)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Spacer(minLength: 4)

            if isHovered {
                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.caption2.weight(.semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Delete")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color.primary.opacity(isHovered ? 0.06 : 0.03))
        }
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onTapGesture(perform: action)
    }
}

private struct EmptyPanelState: View {
    let symbol: String
    let text: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(.secondary)
            Text(text)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
