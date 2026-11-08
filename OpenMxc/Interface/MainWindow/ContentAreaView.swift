import SwiftUI

struct ContentAreaView: View {
    @Environment(BrowserController.self) private var controller

    var body: some View {
        Group {
            if let tab = controller.tabManager.selectedTab {
                content(for: tab)
            } else {
                startPagePlaceholder
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
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
            startPagePlaceholder
        }
    }

    private var startPagePlaceholder: some View {
        VStack(spacing: 20) {
            Image("OpenMxcLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Text(BrowserConfiguration.applicationName)
                .font(.system(size: 28, weight: .semibold))

            Text("A quiet place to browse.")
                .font(.body)
                .foregroundStyle(.secondary)
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
