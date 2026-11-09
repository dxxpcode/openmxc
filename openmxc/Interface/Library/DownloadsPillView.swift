import SwiftUI

/// Transient floating pill for downloads: visible while downloads are in
/// progress, then flashes "Download complete" briefly before fading away.
/// Clicking opens the Library's Downloads section. Hidden in zen mode.
struct DownloadsPillView: View {
    @Environment(BrowserController.self) private var controller

    @State private var flashVisible = false
    @State private var hideTask: Task<Void, Never>?

    private var items: [DownloadItem] { DownloadStore.shared.items }
    private var activeDownloads: [DownloadItem] {
        items.filter { $0.status == .inProgress }
    }
    private var visible: Bool {
        !activeDownloads.isEmpty || flashVisible
    }

    var body: some View {
        Group {
            if visible, !controller.zenMode {
                pill
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(Motion.standard, value: visible && !controller.zenMode)
        .onChange(of: activeDownloads.count) { oldCount, newCount in
            if newCount > 0 {
                hideTask?.cancel()
                flashVisible = false
            } else if oldCount > 0, hasRecentCompletion {
                flashVisible = true
                hideTask?.cancel()
                hideTask = Task { @MainActor in
                    try? await Task.sleep(for: .seconds(6))
                    guard !Task.isCancelled else { return }
                    flashVisible = false
                }
            }
        }
    }

    @ViewBuilder
    private var pill: some View {
        if !activeDownloads.isEmpty {
            activePill
        } else {
            completedPill
        }
    }

    private var activePill: some View {
        Button {
            controller.showLibrary(.downloads)
        } label: {
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                    .frame(width: 14, height: 14)
                Text(activeDownloads.count == 1 ? "Downloading 1 file" : "Downloading \(activeDownloads.count) files")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 14)
            .frame(height: 32)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay { Capsule().strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.5) }
            .shadow(color: .black.opacity(0.18), radius: 12, y: 4)
        }
        .buttonStyle(.plain)
        .help("Show Downloads")
        .accessibilityLabel("Show Downloads")
    }

    private var completedPill: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.green)
            Text(completedLabel)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
            Button {
                flashVisible = false
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 18, height: 18)
                    .background(Color.primary.opacity(0.08), in: Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .help("Dismiss")
            .accessibilityLabel("Dismiss")
        }
        .padding(.leading, 14)
        .padding(.trailing, 6)
        .frame(height: 32)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay { Capsule().strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.5) }
        .shadow(color: .black.opacity(0.18), radius: 12, y: 4)
        .onTapGesture { controller.showLibrary(.downloads) }
    }

    private var hasRecentCompletion: Bool {
        let cutoff = Date().addingTimeInterval(-10)
        return items.contains { item in
            item.status == .completed && (item.completedAt ?? .distantPast) > cutoff
        }
    }

    private var completedLabel: String {
        let completed = items.filter { $0.status == .completed }
        let latest = completed.max { lhs, rhs in
            (lhs.completedAt ?? .distantPast) < (rhs.completedAt ?? .distantPast)
        }
        guard let latest else { return "Download complete" }
        return "\(latest.filename) downloaded"
    }
}
