import SwiftUI

struct MainWindowView: View {
    @Environment(BrowserController.self) private var controller
    @Binding var showAskPanel: Bool

    var body: some View {
        ZStack(alignment: .top) {
            ContentAreaView()
            if !controller.zenMode {
                BrowserToolbar()
                    .padding(.top, 12)
                    .padding(.horizontal, 24)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(
            minWidth: BrowserConstants.minimumWindowWidth,
            minHeight: BrowserConstants.minimumWindowHeight
        )
        .overlay(alignment: .bottom) {
            if showAskPanel {
                AskPagePanel(onClose: { showAskPanel = false })
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .overlay {
            commandPaletteOverlay
        }
        .overlay(alignment: .top) {
            zenExitPill
        }
        .overlay(alignment: .bottomTrailing) {
            DownloadsPillView()
                .padding(.trailing, 24)
                .padding(.bottom, 24)
        }
        .overlay(alignment: .trailing) {
            libraryOverlay
        }
        .background {
            zenEscapeHandler
        }
        .animation(Motion.standard, value: showAskPanel)
        .animation(Motion.standard, value: controller.zenMode)
        .animation(Motion.standard, value: controller.showCommandPalette)
        .animation(Motion.standard, value: controller.librarySection != nil)
    }

    @ViewBuilder
    private var libraryOverlay: some View {
        if let section = controller.librarySection {
            HStack(spacing: 0) {
                Color.black.opacity(0.001)
                    .contentShape(Rectangle())
                    .onTapGesture { controller.closeLibrary() }
                LibraryPanelView(section: section)
                    .frame(width: 400)
                    .background { panelBackground }
                    .overlay(alignment: .leading) {
                        Rectangle()
                            .fill(Color.primary.opacity(0.12))
                            .frame(width: 0.5)
                    }
                    .shadow(color: .black.opacity(colorScheme == .dark ? 0.35 : 0.15), radius: 24, x: -8, y: 0)
            }
            .transition(.move(edge: .trailing).combined(with: .opacity))
        }
    }

    @Environment(\.colorScheme) private var colorScheme

    private var panelBackground: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial)
            Rectangle().fill(colorScheme == .dark ? Color.black.opacity(0.55) : Color.white.opacity(0.6))
        }
    }

    @ViewBuilder
    private var commandPaletteOverlay: some View {
        if controller.showCommandPalette {
            ZStack {
                Color.black.opacity(0.001)
                    .contentShape(Rectangle())
                    .onTapGesture { controller.showCommandPalette = false }
                CommandPaletteView()
                    .padding(.top, 72)
            }
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    /// A quiet floating pill is the only chrome left in zen mode; Esc and ⌘.
    /// exit as well.
    @ViewBuilder
    private var zenExitPill: some View {
        if controller.zenMode {
            Button {
                controller.toggleZenMode()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay { Circle().strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.5) }
            }
            .buttonStyle(.plain)
            .padding(.top, 10)
            .help("Exit Zen Mode (Esc)")
            .accessibilityLabel("Exit Zen Mode")
            .transition(.opacity)
        }
    }

    @ViewBuilder
    private var zenEscapeHandler: some View {
        if controller.zenMode, !controller.showCommandPalette {
            Button("") { controller.toggleZenMode() }
                .keyboardShortcut(.escape, modifiers: [])
                .hidden()
        }
    }
}
