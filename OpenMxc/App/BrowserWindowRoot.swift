import SwiftUI

struct BrowserWindowRoot: View {
    @State private var controller: BrowserController
    @AppStorage("appTheme") private var appTheme = "system"
    @State private var showOnboarding = false
    @State private var window: NSWindow?

    init(isPrivate: Bool = false) {
        _controller = State(initialValue: BrowserController(isPrivate: isPrivate))
    }

    var body: some View {
        MainWindowView()
            .environment(controller)
            .preferredColorScheme(colorScheme)
            .sheet(isPresented: $showOnboarding) {
                OnboardingView()
            }
            .background {
                WindowAccessor { window in
                    self.window = window
                    window?.titleVisibility = .hidden
                    window?.title = ""
                    window?.standardWindowButton(.closeButton)?.isHidden = true
                    window?.standardWindowButton(.miniaturizeButton)?.isHidden = true
                    window?.standardWindowButton(.zoomButton)?.isHidden = true
                    window?.isMovableByWindowBackground = true
                }
            }
            .onAppear {
                showOnboarding = !controller.isPrivate && !AppSettings.bool("onboardingCompleted", default: false)
            }
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
            .modifier(OverlayCommandHandlers(controller: controller, isKeyWindow: isKeyWindow))
            .onDisappear {
                if !controller.isPrivate {
                    SessionStore.shared.unregister(controller)
                }
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

private struct OverlayCommandHandlers: ViewModifier {
    let controller: BrowserController
    let isKeyWindow: Bool

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .openmxcTabSwitcher)) { _ in
                guard isKeyWindow else { return }
                controller.toggleTabSwitcher()
            }
            .onReceive(NotificationCenter.default.publisher(for: .openmxcLibraryPanel)) { _ in
                guard isKeyWindow else { return }
                controller.toggleLibraryPanel()
            }
    }
}
