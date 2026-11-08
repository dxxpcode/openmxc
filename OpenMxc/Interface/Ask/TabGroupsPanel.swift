import SwiftUI

/// Floating "Tab Groups" panel: groups the window's tabs by topic using
/// on-device Apple Intelligence. Clicking a tab switches to it.
struct TabGroupsPanel: View {
    @Environment(BrowserController.self) private var controller
    @Environment(\.colorScheme) private var colorScheme

    let onClose: () -> Void

    @State private var service = TabGroupingService()

    private var tabs: [TabModel] {
        controller.tabManager.tabs
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            content
        }
        .padding(16)
        .frame(width: 520)
        .background(canvasColor, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(borderColor, lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.5 : 0.18), radius: 24, y: 8)
        .task {
            await service.group(tabs: tabs)
        }
        .onExitCommand { onClose() }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.accentColor)
            Text("Tab Groups")
                .font(.system(size: 13, weight: .medium))
            Text("\(tabs.count) tabs")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button {
                Task { await service.group(tabs: tabs) }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
                    .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Regroup tabs")
            .accessibilityLabel("Regroup tabs")
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
            EmptyView()
        case .thinking:
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text("Grouping tabs on-device…")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12)
        case .failed(let message):
            VStack(alignment: .leading, spacing: 10) {
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                tabList(tabs)
            }
        case .grouped(let groups):
            if groups.isEmpty {
                tabList(tabs)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 14) {
                        ForEach(groups) { group in
                            groupSection(group)
                        }
                    }
                }
                .frame(maxHeight: 360)
            }
        }
    }

    private func groupSection(_ group: TabGroupingService.TabGroup) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Text(group.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text("\(group.tabs.count)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 6)
            tabList(group.tabs)
        }
    }

    private func tabList(_ tabs: [TabModel]) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            ForEach(tabs) { tab in
                tabRow(tab)
            }
        }
    }

    private func tabRow(_ tab: TabModel) -> some View {
        let isSelected = tab.id == controller.tabManager.selectedTabID
        return Button {
            controller.tabManager.select(tab)
            onClose()
        } label: {
            HStack(spacing: 8) {
                Group {
                    if let favicon = tab.favicon {
                        Image(nsImage: favicon)
                            .resizable()
                            .frame(width: 16, height: 16)
                    } else {
                        Image(systemName: "globe")
                            .font(.system(size: 11))
                            .foregroundStyle(.tertiary)
                            .frame(width: 16, height: 16)
                    }
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(tab.displayTitle)
                        .font(.callout)
                        .lineLimit(1)
                    Text(tab.navigation.currentURL?.host() ?? "")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                if isSelected {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.primary.opacity(isSelected ? 0.07 : 0))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var canvasColor: Color {
        colorScheme == .dark ? .black : Color(nsColor: .windowBackgroundColor)
    }

    private var borderColor: Color {
        colorScheme == .dark ? Color.primary.opacity(0.16) : Color(nsColor: .separatorColor)
    }
}
