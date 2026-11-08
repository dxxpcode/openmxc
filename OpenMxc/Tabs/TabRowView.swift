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
        HStack(spacing: 10) {
            icon

            if tab.isPinned {
                Text(tab.displayTitle)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                    .truncationMode(.tail)
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text(tab.displayTitle)
                        .font(.body.weight(.medium))
                        .lineLimit(1)
                        .truncationMode(.tail)
                    if let host = tab.navigation.currentURL?.host() {
                        Text(host)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer(minLength: 4)

            if tab.isMuted {
                Image(systemName: "speaker.slash.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }

            if isHovered && !tab.isPinned {
                Button {
                    controller.tabManager.closeTab(tab)
                } label: {
                    Image(systemName: "xmark")
                        .font(.callout.weight(.semibold))
                        .frame(width: 20, height: 20)
                        .background(Color.primary.opacity(0.08), in: Circle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Close Tab")
                .accessibilityLabel("Close Tab")
            }
        }
        .padding(.horizontal, tab.isPinned ? 8 : 12)
        .padding(.vertical, tab.isPinned ? 6 : 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isSelected ? Color.accentColor.opacity(0.22) : (isHovered ? Color.primary.opacity(0.05) : .clear))
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityHint("Double-tap to switch to this tab")
        .accessibilityAction { controller.tabManager.select(tab) }
    }

    private var accessibilityText: String {
        var parts = [tab.displayTitle]
        if let host = tab.navigation.currentURL?.host() {
            parts.append(host)
        }
        if tab.isMuted { parts.append("muted") }
        if tab.isPinned { parts.append("pinned") }
        if isSelected { parts.append("selected") }
        parts.append("tab")
        return parts.joined(separator: ", ")
    }

    @ViewBuilder
    private var icon: some View {
        if tab.isLoading {
            ProgressView()
                .controlSize(.small)
                .frame(width: 22, height: 22)
        } else if let favicon = tab.favicon {
            Image(nsImage: favicon)
                .resizable()
                .scaledToFit()
                .frame(width: 22, height: 22)
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
        } else {
            Image(systemName: "globe")
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(width: 22, height: 22)
                .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
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
