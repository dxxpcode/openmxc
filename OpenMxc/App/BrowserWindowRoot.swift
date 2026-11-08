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
            .toolbar {
                BrowserToolbarContent(controller: controller)
            }
            .preferredColorScheme(colorScheme)
            .sheet(isPresented: $showOnboarding) {
                OnboardingView()
            }
            .background {
                WindowAccessor { window in
                    self.window = window
                    window?.titleVisibility = .hidden
                    window?.title = ""
                }
            }
            .onAppear {
                showOnboarding = !controller.isPrivate && !AppSettings.bool("onboardingCompleted", default: false)
            }
            .modifier(TabCommandHandlers(controller: controller, window: $window))
            .modifier(LibraryCommandHandlers(controller: controller, window: $window))
            .onDisappear {
                if !controller.isPrivate {
                    SessionStore.shared.unregister(controller)
                }
            }
    }

    private var colorScheme: ColorScheme? {
        switch appTheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
}

private struct TabCommandHandlers: ViewModifier {
    let controller: BrowserController
    @Binding var window: NSWindow?

    @Environment(\.openWindow) private var openWindow

    private var isKeyWindow: Bool {
        window?.isKeyWindow ?? false
    }

    func body(content: Content) -> some View {
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
                openWindow(id: BrowserConstants.privateWindowID)
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
            .onReceive(NotificationCenter.default.publisher(for: .openmxcReopenClosedTab)) { _ in
                guard isKeyWindow else { return }
                controller.tabManager.reopenClosedTab()
            }
    }
}

private struct LibraryCommandHandlers: ViewModifier {
    let controller: BrowserController
    @Binding var window: NSWindow?

    private var isKeyWindow: Bool {
        window?.isKeyWindow ?? false
    }

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .openmxcShowLibrary)) { notification in
                guard isKeyWindow,
                      let raw = notification.userInfo?["section"] as? String,
                      let section = LibrarySection(rawValue: raw)
                else { return }
                controller.showLibrary(section)
            }
    }
}
