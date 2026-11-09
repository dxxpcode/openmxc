import SwiftUI

struct BrowserWindowRoot: View {
    @State private var controller: BrowserController
    @AppStorage("appTheme") private var appTheme = "system"
    @State private var showAskPanel = false
    @State private var window: NSWindow?

    init(isPrivate: Bool = false) {
        _controller = State(initialValue: BrowserController(isPrivate: isPrivate))
    }

    var body: some View {
        handleNotifications(
            MainWindowView(showAskPanel: $showAskPanel)
                .environment(controller)
                .preferredColorScheme(colorScheme)
                .background {
                    WindowAccessor { window in
                        self.window = window
                        window?.titleVisibility = .hidden
                        window?.title = ""
                        window?.standardWindowButton(.closeButton)?.isHidden = true
                        window?.standardWindowButton(.miniaturizeButton)?.isHidden = true
                        window?.standardWindowButton(.zoomButton)?.isHidden = true
                        window?.isMovableByWindowBackground = true
                        // Transparent window so the Liquid Glass canvas refracts
                        // the actual Mac desktop instead of an opaque fill.
                        window?.isOpaque = false
                        window?.backgroundColor = .clear
                    }
                }
                .onDisappear {
                    if !controller.isPrivate {
                        SessionStore.shared.unregister(controller)
                    }
                }
        )
    }

    private func handleNotifications<V: View>(_ content: V) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .openmxcNewTab)) { _ in
                guard isKeyWindow else { return }
                controller.newTab()
            }
            .onReceive(NotificationCenter.default.publisher(for: .openmxcCloseTab)) { _ in
                guard isKeyWindow else { return }
                controller.closeSelectedTab()
            }
            .onReceive(NotificationCenter.default.publisher(for: .openmxcToggleSidebar)) { _ in
                guard isKeyWindow else { return }
                controller.toggleSidebar()
            }
            .onReceive(NotificationCenter.default.publisher(for: .openmxcSelectAdjacentTab)) { notification in
                guard isKeyWindow else { return }
                let direction = notification.userInfo?["direction"] as? Int ?? 1
                controller.selectAdjacentTab(direction)
            }
            .onReceive(NotificationCenter.default.publisher(for: .openmxcNewPrivateWindow)) { _ in
                guard isKeyWindow else { return }
                openPrivateWindow()
            }
            .onReceive(NotificationCenter.default.publisher(for: .openmxcFocusAddressBar)) { _ in
                guard isKeyWindow else { return }
                NotificationCenter.default.post(name: .openmxcAddressBarFocus, object: nil)
            }
            .onReceive(NotificationCenter.default.publisher(for: .openmxcAskPage)) { _ in
                guard isKeyWindow else { return }
                showAskPanel = true
            }
            .onReceive(NotificationCenter.default.publisher(for: .openmxcCommandPalette)) { _ in
                guard isKeyWindow else { return }
                controller.showCommandPalette = true
            }
            .onReceive(NotificationCenter.default.publisher(for: .openmxcToggleZenMode)) { _ in
                guard isKeyWindow else { return }
                controller.toggleZenMode()
            }
            .onReceive(NotificationCenter.default.publisher(for: .openmxcToggleReaderMode)) { _ in
                guard isKeyWindow else { return }
                controller.selectedNavigation?.toggleReaderMode()
            }
            .onReceive(NotificationCenter.default.publisher(for: .openmxcToggleFavorite)) { _ in
                guard isKeyWindow else { return }
                controller.toggleFavorite()
            }
            .onReceive(NotificationCenter.default.publisher(for: .openmxcSelectTabIndex)) { notification in
                guard isKeyWindow,
                      let index = notification.userInfo?["index"] as? Int
                else { return }
                controller.selectTab(at: index)
            }
            .onReceive(NotificationCenter.default.publisher(for: .openmxcCloseWindow)) { _ in
                guard isKeyWindow else { return }
                window?.close()
            }
            .onReceive(NotificationCenter.default.publisher(for: .openmxcMinimizeWindow)) { _ in
                guard isKeyWindow else { return }
                window?.miniaturize(nil)
            }
            .onReceive(NotificationCenter.default.publisher(for: .openmxcZoomWindow)) { _ in
                guard isKeyWindow else { return }
                window?.zoom(nil)
            }
    }

    private var isKeyWindow: Bool {
        window?.isKeyWindow ?? false
    }

    @Environment(\.openWindow) private var openWindow

    private func openPrivateWindow() {
        openWindow(id: BrowserConstants.privateWindowID)
    }

    private var colorScheme: ColorScheme? {
        switch appTheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
}
