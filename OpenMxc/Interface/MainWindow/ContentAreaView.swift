import SwiftUI

struct ContentAreaView: View {
    @Environment(BrowserController.self) private var controller

    var body: some View {
        Group {
            if let section = controller.librarySection {
                LibraryView(section: section)
            } else if let tab = controller.tabManager.selectedTab {
                content(for: tab)
            } else {
                StartPageView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(OX.background)
        .onChange(of: controller.tabManager.selectedTabID) { _, _ in
            controller.librarySection = nil
        }
    }

    @ViewBuilder
    private func content(for tab: TabModel) -> some View {
        let navigation = tab.navigation
        if navigation.webContentCrashed {
            crashView(for: tab)
        } else if let loadError = navigation.loadError {
            loadErrorView(loadError, for: tab)
        } else if navigation.hasCommittedNavigation || navigation.isLoading {
            WebViewContainer(webView: navigation.webView)
                .id(tab.id)
        } else {
            StartPageView()
        }
    }

    private func crashView(for tab: TabModel) -> some View {
        statusView(
            symbol: "exclamationmark.triangle",
            title: "This webpage quit unexpectedly",
            message: "The content process stopped. Reload to try again."
        ) {
            Button("Reload") {
                tab.navigation.recoverFromCrash()
            }
            .keyboardShortcut(.defaultAction)
        }
    }

    private func loadErrorView(_ message: String, for tab: TabModel) -> some View {
        statusView(
            symbol: "safari",
            title: "This webpage could not be loaded",
            message: message
        ) {
            Button("Try Again") {
                tab.navigation.reload()
            }
            .keyboardShortcut(.defaultAction)
        }
    }

    private func statusView<Actions: View>(
        symbol: String,
        title: String,
        message: String,
        @ViewBuilder actions: () -> Actions
    ) -> some View {
        VStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            actions()
                .padding(.top, 4)
        }
        .padding(32)
        .frame(maxWidth: 420)
    }
}
