import AppKit
import SwiftUI

struct TabSwitcherView: View {
    @Environment(BrowserController.self) private var controller

    @State private var highlightedID: UUID?
    @FocusState private var isFocused: Bool

    private var tabs: [TabModel] {
        controller.tabManager.tabs
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.25)
                .ignoresSafeArea()
                .onTapGesture { close() }

            VStack(spacing: 0) {
                header
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(tabs) { tab in
                            row(for: tab)
                        }
                    }
                    .padding(8)
                }
                .frame(maxHeight: 420)
            }
            .frame(width: 480)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 0.5)
            }
            .shadow(radius: 24)
        }
        .focusable()
        .focused($isFocused)
        .onKeyPress(.upArrow) {
            moveHighlight(by: -1)
            return .handled
        }
        .onKeyPress(.downArrow) {
            moveHighlight(by: 1)
            return .handled
        }
        .onKeyPress(.return) {
            openHighlighted()
            return .handled
        }
        .onKeyPress(.escape) {
            close()
            return .handled
        }
        .onAppear {
            highlightedID = controller.tabManager.selectedTabID ?? tabs.first?.id
            isFocused = true
        }
    }

    private var header: some View {
        HStack {
            Text("Tabs")
                .font(.headline)
            Spacer()
            Text("\(tabs.count)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button {
                close()
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.borderless)
            .help("Close (Esc)")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private func row(for tab: TabModel) -> some View {
        let isHighlighted = tab.id == highlightedID
        let isSelected = tab.id == controller.tabManager.selectedTabID
        return HStack(spacing: 8) {
            icon(for: tab)

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

            Spacer(minLength: 4)

            if isSelected {
                Image(systemName: "checkmark")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
            }

            if isHighlighted && !tab.isPinned {
                Button {
                    controller.tabManager.closeTab(tab)
                    if tabs.isEmpty {
                        close()
                    } else if highlightedID == tab.id {
                        highlightedID = tabs.first?.id
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption2.weight(.semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Close Tab")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(isHighlighted ? Color.accentColor.opacity(0.16) : .clear)
        }
        .contentShape(Rectangle())
        .onHover { hovering in
            if hovering {
                highlightedID = tab.id
            }
        }
        .onTapGesture {
            highlightedID = tab.id
            openHighlighted()
        }
    }

    @ViewBuilder
    private func icon(for tab: TabModel) -> some View {
        if let favicon = tab.favicon {
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

    private func moveHighlight(by offset: Int) {
        guard !tabs.isEmpty else { return }
        let currentIndex = tabs.firstIndex { $0.id == highlightedID } ?? 0
        let count = tabs.count
        let next = (currentIndex + offset + count) % count
        highlightedID = tabs[next].id
    }

    private func openHighlighted() {
        guard let id = highlightedID,
              let tab = tabs.first(where: { $0.id == id })
        else { return }
        controller.tabManager.select(tab)
        close()
    }

    private func close() {
        controller.showTabSwitcher = false
    }
}
