import SwiftUI

struct MainWindowView: View {
    @Environment(BrowserController.self) private var controller

    var body: some View {
        VStack(spacing: 0) {
            BrowserToolbar()
            ModernTabStrip()
            loadingProgress
            ContentAreaView()
        }
        .frame(
            minWidth: BrowserConstants.minimumWindowWidth,
            minHeight: BrowserConstants.minimumWindowHeight
        )
    }

    @ViewBuilder
    private var loadingProgress: some View {
        if let navigation = controller.selectedNavigation, navigation.isLoading {
            ProgressView(value: navigation.estimatedProgress)
                .progressViewStyle(.linear)
                .tint(.accentColor)
                .frame(height: 1)
        }
    }
}

private struct ModernTabStrip: View {
    @Environment(BrowserController.self) private var controller

    var body: some View {
        HStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(controller.tabManager.tabs) { tab in
                        ModernTabItem(tab: tab)
                    }
                }
                .padding(.horizontal, 18)
            }

            Button {
                controller.newTab()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .medium))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.borderless)
            .help("New Tab")
            .padding(.trailing, 14)
        }
        .frame(height: 34)
        .background(Color(nsColor: .controlBackgroundColor))
        .overlay(alignment: .bottom) {
            Divider()
        }
    }
}

private struct ModernTabItem: View {
    @Environment(BrowserController.self) private var controller
    let tab: TabModel

    @State private var isHovered = false

    private var isSelected: Bool {
        controller.tabManager.selectedTabID == tab.id
    }

    var body: some View {
        HStack(spacing: 7) {
            favicon

            Text(tab.displayTitle)
                .font(.system(size: 12, weight: isSelected ? .medium : .regular))
                .lineLimit(1)
                .frame(maxWidth: 150)

            if isHovered && controller.tabManager.tabs.count > 1 {
                Button {
                    controller.tabManager.closeTab(tab)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .semibold))
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
            }
        }
        .foregroundStyle(isSelected ? .primary : .secondary)
        .padding(.horizontal, 10)
        .frame(height: 28)
        .background {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(isSelected ? Color(nsColor: .selectedContentBackgroundColor).opacity(0.18) : .clear)
        }
        .overlay(alignment: .bottom) {
            if isSelected {
                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: 28, height: 2)
                    .offset(y: 3)
            }
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
        .contextMenu {
            Button("Close Tab") {
                controller.tabManager.closeTab(tab)
            }
            Button(tab.isPinned ? "Unpin Tab" : "Pin Tab") {
                controller.tabManager.togglePin(tab)
            }
        }
        .help(tab.address.isEmpty ? tab.displayTitle : tab.address)
        .accessibilityLabel(tab.displayTitle)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private var favicon: some View {
        if let favicon = tab.favicon {
            Image(nsImage: favicon)
                .resizable()
                .scaledToFit()
                .frame(width: 14, height: 14)
        } else {
            Image(systemName: tab.isLoading ? "circle.dotted" : "globe")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .frame(width: 14, height: 14)
        }
    }
}
