import SwiftUI

struct BrowserToolbar: View {
    @Environment(BrowserController.self) private var controller
    @FocusState private var isAddressFocused: Bool
    @State private var addressText = ""
    @State private var window: NSWindow?
    @AppStorage("appTheme") private var appTheme = "system"
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 16) {
            HStack(spacing: 2) {
                navButton(
                    symbol: "chevron.left",
                    help: "Back",
                    enabled: controller.selectedNavigation?.canGoBack ?? false
                ) {
                    controller.selectedNavigation?.goBack()
                }

                navButton(
                    symbol: "chevron.right",
                    help: "Forward",
                    enabled: controller.selectedNavigation?.canGoForward ?? false
                ) {
                    controller.selectedNavigation?.goForward()
                }

                if controller.selectedNavigation?.isLoading ?? false {
                    navButton(symbol: "xmark", help: "Stop") {
                        controller.selectedNavigation?.stopLoading()
                    }
                } else {
                    navButton(
                        symbol: "arrow.clockwise",
                        help: "Reload",
                        enabled: controller.selectedNavigation?.hasCommittedNavigation ?? false
                    ) {
                        controller.selectedNavigation?.reload()
                    }
                }
            }

            addressField

            Button {
                controller.toggleFavorite()
            } label: {
                Image(systemName: controller.currentPageIsFavorite ? "star.fill" : "star")
            }
            .buttonStyle(ToolbarIconStyle(tint: controller.currentPageIsFavorite ? Color.accentColor : nil))
            .help(controller.currentPageIsFavorite ? "Remove Favorite" : "Add to Favorites")
            .disabled(controller.selectedNavigation?.currentURL == nil)
            .accessibilityLabel(controller.currentPageIsFavorite ? "Remove Favorite" : "Add to Favorites")

            shareButton

            Button {
                appTheme = colorScheme == .dark ? "light" : "dark"
            } label: {
                Image(systemName: colorScheme == .dark ? "sun.max" : "moon")
            }
            .buttonStyle(ToolbarIconStyle())
            .help(colorScheme == .dark ? "Switch to Light Mode" : "Switch to Dark Mode")
            .accessibilityLabel(colorScheme == .dark ? "Switch to Light Mode" : "Switch to Dark Mode")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .frame(height: BrowserConstants.toolbarHeight)
        .background(canvasColor)
        .onChange(of: controller.tabManager.selectedTabID) { _, _ in
            syncAddressText()
        }
        .onChange(of: controller.selectedNavigation?.currentURL) { _, _ in
            syncAddressText()
        }
        .onReceive(NotificationCenter.default.publisher(for: .openmxcAddressBarFocus)) { _ in
            guard window?.isKeyWindow == true else { return }
            isAddressFocused = true
        }
        .background {
            WindowAccessor { window in
                self.window = window
            }
        }
    }

    private var canvasColor: Color {
        colorScheme == .dark ? .black : Color(nsColor: .windowBackgroundColor)
    }

    @ViewBuilder
    private var shareButton: some View {
        if let url = controller.selectedNavigation?.currentURL {
            ShareLink(item: url) {
                Image(systemName: "square.and.arrow.up")
            }
            .buttonStyle(ToolbarIconStyle())
            .help("Share")
            .accessibilityLabel("Share")
        } else {
            navButton(symbol: "square.and.arrow.up", help: "Share", enabled: false) {}
        }
    }

    private var addressField: some View {
        SearchField(
            placeholder: "Search or enter address",
            text: $addressText,
            height: 32,
            focus: $isAddressFocused
        ) {
            controller.navigate(to: addressText)
            isAddressFocused = false
        }
        .frame(maxWidth: 640)
    }

    private func syncAddressText() {
        guard !isAddressFocused else { return }
        addressText = controller.selectedNavigation?.currentURL?.absoluteString ?? ""
    }

    private func navButton(
        symbol: String,
        help: String,
        enabled: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
        }
        .buttonStyle(ToolbarIconStyle())
        .help(help)
        .disabled(!enabled)
    }
}

/// Quiet monochrome toolbar button: subtle rounded hover fill, press dimming,
/// and a smooth transition. Keeps the chrome minimal while feeling tactile.
private struct ToolbarIconStyle: ButtonStyle {
    var tint: Color? = nil

    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12.5, weight: .medium))
            .foregroundStyle(labelColor(isPressed: configuration.isPressed))
            .frame(width: 30, height: 30)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.primary.opacity(backgroundOpacity(isPressed: configuration.isPressed)))
            }
            .contentShape(Rectangle())
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.12)) {
                    isHovered = hovering
                }
            }
            .opacity(isEnabled ? 1 : 0.4)
            .animation(.easeInOut(duration: 0.12), value: isHovered)
    }

    private func labelColor(isPressed: Bool) -> Color {
        if let tint { return tint }
        if isPressed { return Color.primary.opacity(0.65) }
        return Color.primary.opacity(isHovered ? 0.95 : 0.72)
    }

    private func backgroundOpacity(isPressed: Bool) -> Double {
        if isPressed { return 0.12 }
        return isHovered ? 0.07 : 0
    }
}
