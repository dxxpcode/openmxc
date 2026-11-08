import AppKit
import SwiftUI

/// Native macOS toolbar content: sidebar toggle, navigation, address/search
/// field, reload/stop, downloads, new tab, and browser menu.
struct BrowserToolbarContent: ToolbarContent {
    let controller: BrowserController

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .navigation) {
            Button {
                controller.toggleSidebar()
            } label: {
                Label("Sidebar", systemImage: "sidebar.left")
            }
            .help("Toggle Sidebar")
            .accessibilityLabel("Toggle Sidebar")

            Button {
                controller.selectedNavigation?.goBack()
            } label: {
                Label("Back", systemImage: "chevron.left")
            }
            .disabled(!(controller.selectedNavigation?.canGoBack ?? false))
            .help("Back")
            .accessibilityLabel("Back")

            Button {
                controller.selectedNavigation?.goForward()
            } label: {
                Label("Forward", systemImage: "chevron.right")
            }
            .disabled(!(controller.selectedNavigation?.canGoForward ?? false))
            .help("Forward")
            .accessibilityLabel("Forward")
        }

        ToolbarItem(placement: .principal) {
            AddressFieldView(controller: controller)
        }

        ToolbarItemGroup(placement: .primaryAction) {
            if controller.selectedNavigation?.isLoading ?? false {
                Button {
                    controller.selectedNavigation?.stopLoading()
                } label: {
                    Label("Stop", systemImage: "xmark")
                }
                .help("Stop Loading")
                .accessibilityLabel("Stop Loading")
            } else {
                Button {
                    controller.selectedNavigation?.reload()
                } label: {
                    Label("Reload", systemImage: "arrow.clockwise")
                }
                .disabled(!(controller.selectedNavigation?.hasCommittedNavigation ?? false))
                .help("Reload")
                .accessibilityLabel("Reload")
            }

            Button {
                controller.showLibrary(.downloads)
            } label: {
                Label("Downloads", systemImage: "arrow.down.circle")
            }
            .help("Downloads")
            .accessibilityLabel("Downloads")

            Button {
                controller.newTab()
            } label: {
                Label("New Tab", systemImage: "plus")
            }
            .help("New Tab")
            .accessibilityLabel("New Tab")

            PageInfoButton(controller: controller)

            BrowserMenu(controller: controller)
        }
    }
}

private struct AddressFieldView: View {
    let controller: BrowserController
    @FocusState private var isFocused: Bool
    @State private var addressText = ""
    @State private var window: NSWindow?

    var body: some View {
        TextField("Search or enter address", text: $addressText)
            .textFieldStyle(.plain)
            .focused($isFocused)
            .onSubmit {
                controller.navigate(to: addressText)
                isFocused = false
            }
            .frame(minWidth: 220, idealWidth: 380, maxWidth: 560)
            .onChange(of: controller.tabManager.selectedTabID) { _, _ in syncAddressText() }
            .onChange(of: controller.selectedNavigation?.currentURL) { _, _ in syncAddressText() }
            .onReceive(NotificationCenter.default.publisher(for: .openmxcAddressBarFocus)) { _ in
                guard window?.isKeyWindow == true else { return }
                isFocused = true
            }
            .background {
                WindowAccessor { window in
                    self.window = window
                }
            }
    }

    private func syncAddressText() {
        guard !isFocused else { return }
        addressText = controller.selectedNavigation?.currentURL?.absoluteString ?? ""
    }
}

private struct PageInfoButton: View {
    let controller: BrowserController
    @State private var isPresented = false

    var body: some View {
        let url = controller.selectedNavigation?.currentURL
        Button {
            isPresented.toggle()
        } label: {
            Label("Page Info", systemImage: securitySymbol(for: url))
        }
        .help("Page Info")
        .accessibilityLabel("Page Info")
        .popover(isPresented: $isPresented, arrowEdge: .bottom) {
            pageInfoContent(url: url)
                .padding(16)
                .frame(minWidth: 280)
        }
    }

    private func securitySymbol(for url: URL?) -> String {
        switch url?.scheme {
        case "https": return "lock.fill"
        case "http": return "lock.open.fill"
        default: return "info.circle"
        }
    }

    @ViewBuilder
    private func pageInfoContent(url: URL?) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if let url {
                Text(url.host() ?? url.absoluteString)
                    .font(.headline)
                Text(url.absoluteString)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                Divider()
            }
            Label(securityDescription(for: url), systemImage: securitySymbol(for: url))
                .font(.callout)
            Text("HTTPS encrypts the connection to this website, but it does not guarantee that the website is trustworthy.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func securityDescription(for url: URL?) -> String {
        switch url?.scheme {
        case "https": return "Connection is encrypted"
        case "http": return "Connection is not encrypted"
        default: return "No web address loaded"
        }
    }
}

private struct BrowserMenu: View {
    let controller: BrowserController

    var body: some View {
        Menu {
            Button("Add to Favorites") {
                controller.toggleFavorite()
            }
            .disabled(controller.selectedNavigation?.currentURL == nil)

            Divider()

            Button("Show Bookmarks") {
                controller.showLibrary(.bookmarks)
            }
            Button("Show History") {
                controller.showLibrary(.history)
            }
            Button("Show Downloads") {
                controller.showLibrary(.downloads)
            }

            Divider()

            Button("New Private Window") {
                NotificationCenter.default.post(name: .openmxcNewPrivateWindow, object: nil)
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])

            Divider()

            Button("Reload Page") {
                controller.selectedNavigation?.reload()
            }
            .keyboardShortcut("r", modifiers: .command)
            .disabled(!(controller.selectedNavigation?.hasCommittedNavigation ?? false))

            Button("Stop Loading") {
                controller.selectedNavigation?.stopLoading()
            }
            .disabled(!(controller.selectedNavigation?.isLoading ?? false))
        } label: {
            Label("Browser Menu", systemImage: "ellipsis")
        }
        .help("Browser Menu")
        .accessibilityLabel("Browser Menu")
    }
}
