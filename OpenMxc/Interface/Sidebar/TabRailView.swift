import SwiftUI

/// Slim vertical tab rail: a frosted-glass sidebar listing open tabs.
/// Supports selection, hover-close, drag reordering, pinning and the full
/// context menu via `TabRowView`; collapsible and width-resizable from the
/// trailing edge.
struct TabRailView: View {
    @Environment(BrowserController.self) private var controller
    @Environment(\.colorScheme) private var colorScheme

    @State private var resizeStartWidth: CGFloat?

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                header
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 1) {
                        ForEach(controller.tabManager.tabs) { tab in
                            TabRowView(tab: tab)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                }
            }
            .frame(width: controller.sidebarWidth)

            resizeHandle
        }
        .background(railBackground)
        .overlay(alignment: .trailing) { trailingHairline }
    }

    private var header: some View {
        HStack(spacing: 4) {
            Button {
                controller.newTab()
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(ToolbarIconStyle())
            .help("New Tab")
            .accessibilityLabel("New Tab")

            Spacer()

            Button {
                controller.toggleSidebar()
            } label: {
                Image(systemName: "sidebar.left")
            }
            .buttonStyle(ToolbarIconStyle())
            .help("Hide Tab Rail")
            .accessibilityLabel("Hide Tab Rail")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }

    private var railBackground: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial)
            Rectangle().fill(colorScheme == .dark ? Color.black.opacity(0.45) : Color.white.opacity(0.35))
        }
    }

    private var trailingHairline: some View {
        Rectangle()
            .fill(Color.primary.opacity(colorScheme == .dark ? 0.12 : 0.08))
            .frame(width: 0.5)
    }

    private var resizeHandle: some View {
        Rectangle()
            .fill(.clear)
            .frame(width: 6)
            .contentShape(Rectangle())
            .onHover { hovering in
                if hovering {
                    NSCursor.resizeLeftRight.push()
                } else {
                    NSCursor.pop()
                }
            }
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        if resizeStartWidth == nil {
                            resizeStartWidth = controller.sidebarWidth
                        }
                        if let start = resizeStartWidth {
                            controller.setSidebarWidth(start + value.translation.width)
                        }
                    }
                    .onEnded { _ in
                        resizeStartWidth = nil
                    }
            )
    }
}
