import AppKit
import SwiftUI

struct DownloadsLibraryView: View {
    private var store: DownloadStore { .shared }

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            listContent
        }
    }

    private var toolbar: some View {
        HStack {
            Text("Downloads")
                .font(.headline)
            Spacer()
            Button("Clear Completed") {
                store.clearCompleted()
            }
            .disabled(!store.items.contains { $0.status != .inProgress })
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var listContent: some View {
        if store.items.isEmpty {
            ContentUnavailableView(
                "Downloads",
                systemImage: "arrow.down.circle",
                description: Text("Files you download will appear here.")
            )
        } else {
            List(store.items) { item in
                row(for: item)
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
                        Divider()
                        Button("Remove", role: .destructive) {
                            store.remove(item)
                        }
                    }
            }
        }
    }

    private func row(for item: DownloadItem) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon(for: item.status))
                .foregroundStyle(color(for: item.status))
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.filename)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(statusText(for: item))
                    if let size = formattedSize(item.fileSize) {
                        Text(size)
                    }
                    Text(item.createdAt, style: .relative)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private func icon(for status: DownloadStatus) -> String {
        switch status {
        case .inProgress: return "arrow.down.circle"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
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
        case .inProgress:
            if let total = item.totalBytes, total > 0, item.bytesReceived > 0 {
                let percent = Int(Double(item.bytesReceived) / Double(total) * 100)
                return "Downloading… \(percent)%"
            }
            return "Downloading…"
        case .completed: return "Completed"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        }
    }

    private func formattedSize(_ bytes: Int64?) -> String? {
        guard let bytes, bytes > 0 else { return nil }
        return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}
