import AppKit
import SwiftUI

struct MainWindowView: View {
    @Environment(BrowserController.self) private var controller

    @State private var sidebarDragStartWidth: CGFloat = 0

    var body: some View {
        HStack(spacing: 0) {
            if controller.sidebarIsVisible {
                TabSidebarView()
                    .frame(width: controller.sidebarWidth)
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }

            if controller.sidebarIsVisible {
                sidebarResizeHandle
            }

            Divider()

            VStack(spacing: 0) {
                BrowserToolbar()
                loadingProgress
                Divider()
                ContentAreaView()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(
            minWidth: BrowserConstants.minimumWindowWidth,
            minHeight: BrowserConstants.minimumWindowHeight
        )
        .overlay(alignment: .topLeading) {
            shortcutButtons
        }
    }

    private var sidebarResizeHandle: some View {
        Color.clear
            .frame(width: 6)
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .onHover { hovering in
                if hovering {
                    NSCursor.resizeLeftRight.push()
                } else {
                    NSCursor.pop()
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if sidebarDragStartWidth == 0 {
                            sidebarDragStartWidth = controller.sidebarWidth
                        }
                        controller.setSidebarWidth(sidebarDragStartWidth + value.translation.width)
                    }
                    .onEnded { _ in
                        sidebarDragStartWidth = 0
                    }
            )
    }

    private var shortcutButtons: some View {
        VStack(spacing: 0) {
            Button("New Tab") { controller.newTab() }
                .keyboardShortcut("t", modifiers: .command)
            Button("Close Tab") { controller.closeSelectedTab() }
                .keyboardShortcut("w", modifiers: .command)
        }
        .opacity(0)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var loadingProgress: some View {
        if let navigation = controller.selectedNavigation, navigation.isLoading {
            ProgressView(value: navigation.estimatedProgress)
                .progressViewStyle(.linear)
                .frame(height: 2)
        }
    }
}
