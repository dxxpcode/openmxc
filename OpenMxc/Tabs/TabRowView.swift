import AppKit
import SwiftUI

struct TabRowView: View {
    @Environment(BrowserController.self) private var controller
    let tab: TabModel

    @State private var isHovered = false

    private var isSelected: Bool {
        controller.tabManager.selectedTabID == tab.id
    }

    var body: some View {
        HStack(spacing: 8) {
            icon

            if tab.isPinned {
                Text(tab.displayTitle)
                    .font(.callout)
                    .lineLimit(1)
                    .truncationMode(.tail)
            } else {
                VStack(alignment: .leading, spacing: 1) {
                    Text(tab.displayTitle)
                        .font(.callout)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    if let host = tab.navigation.currentURL?.host() {
                        Text(host)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer(minLength: 4)

            if tab.isMuted {
                Image(systemName: "speaker.slash.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if isHovered && !tab.isPinned {
                Button {
                    controller.tabManager.closeTab(tab)
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption2.weight(.semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Close Tab")
            }
        }
        .padding(.horizontal, tab.isPinned ? 6 : 8)
        .padding(.vertical, tab.isPinned ? 5 : 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(isSelected ? Color.accentColor.opacity(0.18) : Color.clear)
        }
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .onTapGesture {
            controller.tabManager.select(tab)
        }
        .draggable(tab.id.uuidString)
        .dropDestination(for: String.self) { items, _ in
            guard let rawID = items.first, let draggedID = UUID(uuidString: rawID) else {
                return false
            }
            controller.tabManager.moveTab(draggedID, onto: tab.id)
            return true
        }
        .contextMenu { contextMenu }
        .help(tab.address.isEmpty ? tab.displayTitle : tab.address)
    }

    @ViewBuilder
    private var icon: some View {
        if tab.isLoading {
            ProgressView()
                .controlSize(.small)
                .frame(width: 16, height: 16)
        } else if let favicon = tab.favicon {
            Image(nsImage: favicon)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
        } else {
            Image(systemName: "globe")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 16, height: 16)
        }
    }

    @ViewBuilder
    private var contextMenu: some View {
        Button("New Tab") { controller.newTab() }
        Divider()
        Button(tab.isPinned ? "Unpin Tab" : "Pin Tab") {
            controller.tabManager.togglePin(tab)
        }
        Button("Duplicate Tab") {
            controller.tabManager.duplicateTab(tab)
        }
        Button("Reload") {
            tab.reload()
        }
        Button(tab.isMuted ? "Unmute Tab" : "Mute Tab") {
            tab.setMuted(!tab.isMuted)
        }
        Divider()
        Button("Copy Address") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(tab.address, forType: .string)
        }
        .disabled(tab.address.isEmpty)
        Divider()
        Button("Close Tab") {
            controller.tabManager.closeTab(tab)
        }
        Button("Close Other Tabs") {
            controller.tabManager.closeOtherTabs(keeping: tab)
        }
        .disabled(controller.tabManager.tabs.count <= 1)
    }
}
