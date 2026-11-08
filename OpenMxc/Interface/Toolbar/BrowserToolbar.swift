import SwiftUI

struct BrowserToolbar: View {
    @Environment(BrowserController.self) private var controller
    @FocusState private var isAddressFocused: Bool
    @State private var addressText = ""
    @State private var window: NSWindow?

    var body: some View {
        HStack(spacing: 8) {
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

            addressField

            Button {
                controller.toggleFavorite()
            } label: {
                Image(systemName: controller.currentPageIsFavorite ? "star.fill" : "star")
            }
            .buttonStyle(.borderless)
            .help(controller.currentPageIsFavorite ? "Remove Favorite" : "Add to Favorites")
            .disabled(controller.selectedNavigation?.currentURL == nil)
            .accessibilityLabel(controller.currentPageIsFavorite ? "Remove Favorite" : "Add to Favorites")

            shareButton

            navButton(symbol: "plus", help: "New Tab") {
                controller.newTab()
            }

            Button {
                controller.toggleSidebar()
            } label: {
                Image(systemName: "sidebar.left")
            }
            .buttonStyle(.borderless)
            .help("Toggle Sidebar")
            .accessibilityLabel("Toggle Sidebar")
        }
        .padding(.horizontal, 12)
        .frame(height: BrowserConstants.toolbarHeight)
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

    @ViewBuilder
    private var shareButton: some View {
        if let url = controller.selectedNavigation?.currentURL {
            ShareLink(item: url) {
                Image(systemName: "square.and.arrow.up")
            }
            .buttonStyle(.borderless)
            .help("Share")
            .accessibilityLabel("Share")
        } else {
            navButton(symbol: "square.and.arrow.up", help: "Share", enabled: false) {}
        }
    }

    private var addressField: some View {
        TextField("Search or enter address", text: $addressText)
            .textFieldStyle(.plain)
            .font(.body)
            .focused($isAddressFocused)
            .onSubmit {
                controller.navigate(to: addressText)
                isAddressFocused = false
            }
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity)
            .frame(height: 30)
            .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 0.5)
            }
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
        .buttonStyle(.borderless)
        .help(help)
        .disabled(!enabled)
    }
}
