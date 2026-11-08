import SwiftUI

struct BrowserToolbar: View {
    @Environment(BrowserController.self) private var controller
    @FocusState private var isAddressFocused: Bool
    @State private var addressText = ""

    var body: some View {
        HStack(spacing: 8) {
            navButton(
                symbol: "chevron.left",
                help: "Back",
                enabled: controller.navigation.canGoBack
            ) {
                controller.navigation.goBack()
            }

            navButton(
                symbol: "chevron.right",
                help: "Forward",
                enabled: controller.navigation.canGoForward
            ) {
                controller.navigation.goForward()
            }

            if controller.navigation.isLoading {
                navButton(symbol: "xmark", help: "Stop") {
                    controller.navigation.stopLoading()
                }
            } else {
                navButton(
                    symbol: "arrow.clockwise",
                    help: "Reload",
                    enabled: controller.navigation.hasCommittedNavigation
                ) {
                    controller.navigation.reload()
                }
            }

            addressField

            navButton(symbol: "plus", help: "New Tab", enabled: false) {}

            Button {
                controller.toggleSidebar()
            } label: {
                Image(systemName: "sidebar.left")
            }
            .buttonStyle(.borderless)
            .help("Toggle Sidebar")
        }
        .padding(.horizontal, 12)
        .frame(height: BrowserConstants.toolbarHeight)
        .overlay(alignment: .topLeading) {
            Button("Focus Address Bar") {
                isAddressFocused = true
            }
            .keyboardShortcut("l", modifiers: .command)
            .opacity(0)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
        .onChange(of: controller.navigation.currentURL) { _, url in
            guard !isAddressFocused else { return }
            addressText = url?.absoluteString ?? ""
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
