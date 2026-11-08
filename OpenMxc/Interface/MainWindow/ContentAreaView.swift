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
        .background(Color(nsColor: .windowBackgroundColor))
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
            .buttonStyle(.borderedProminent)
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
            .buttonStyle(.borderedProminent)
        }
    }

    private func statusView<Actions: View>(
        symbol: String,
        title: String,
        message: String,
        @ViewBuilder actions: () -> Actions
    ) -> some View {
        VStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.secondary)
                .frame(width: 72, height: 72)
                .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            Text(title)
                .font(.title3.weight(.semibold))
            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 380)
            actions()
                .padding(.top, 6)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
