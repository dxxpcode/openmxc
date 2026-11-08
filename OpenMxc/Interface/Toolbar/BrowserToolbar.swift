import AppKit
import SwiftUI

struct BrowserToolbar: View {
    @Environment(BrowserController.self) private var controller
    @FocusState private var isAddressFocused: Bool
    @State private var addressText = ""
    @State private var window: NSWindow?

    var body: some View {
        HStack(spacing: 8) {
            navButton("sidebar.left", help: "Toggle Sidebar (⇧⌘S)") {
                controller.toggleSidebar()
            }

            navButton("chevron.left", help: "Back (⌘[)", enabled: controller.selectedNavigation?.canGoBack ?? false) {
                controller.selectedNavigation?.goBack()
            }
            navButton("chevron.right", help: "Forward (⌘])", enabled: controller.selectedNavigation?.canGoForward ?? false) {
                controller.selectedNavigation?.goForward()
            }

            if controller.selectedNavigation?.isLoading ?? false {
                navButton("xmark", help: "Stop") {
                    controller.selectedNavigation?.stopLoading()
                }
            } else {
                navButton("arrow.clockwise", help: "Reload (⌘R)", enabled: controller.selectedNavigation?.hasCommittedNavigation ?? false) {
                    controller.selectedNavigation?.reload()
                }
            }

            addressField

            Button {
                controller.toggleFavorite()
            } label: {
                Image(systemName: controller.currentPageIsFavorite ? "star.fill" : "star")
                    .foregroundStyle(controller.currentPageIsFavorite ? OX.accent : OX.textSecondary)
            }
            .buttonStyle(.oxIcon)
            .help("Favorite (⌘D)")
            .disabled(controller.selectedNavigation?.currentURL == nil)

            if let url = controller.selectedNavigation?.currentURL {
                ShareLink(item: url) {
                    Image(systemName: "square.and.arrow.up")
                }
                .buttonStyle(.oxIcon)
                .help("Share")
            }

            navButton("plus", help: "New Tab (⌘T)") {
                controller.newTab()
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 40)
        .background(OX.background)
        .overlay(alignment: .bottom) {
            Rectangle().fill(OX.border).frame(height: 1)
        }
        .onChange(of: controller.tabManager.selectedTabID) { _, _ in syncAddressText() }
        .onChange(of: controller.selectedNavigation?.currentURL) { _, _ in syncAddressText() }
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

    private var addressField: some View {
        HStack(spacing: 6) {
            Text(">")
                .font(OX.mono(.callout, weight: .bold))
                .foregroundStyle(OX.accent)
            TextField("url or search — ⏎", text: $addressText)
                .textFieldStyle(.plain)
                .font(OX.mono(.callout))
                .foregroundStyle(OX.textPrimary)
                .focused($isAddressFocused)
                .onSubmit {
                    controller.navigate(to: addressText)
                    isAddressFocused = false
                }
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
        .frame(height: 26)
        .background(OX.surface, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .strokeBorder(isAddressFocused ? OX.accent.opacity(0.6) : OX.border, lineWidth: 1)
        }
    }

    private func syncAddressText() {
        guard !isAddressFocused else { return }
        addressText = controller.selectedNavigation?.currentURL?.absoluteString ?? ""
    }

    private func navButton(
        _ symbol: String,
        help: String,
        enabled: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
        }
        .buttonStyle(.oxIcon)
        .help(help)
        .disabled(!enabled)
    }
}
