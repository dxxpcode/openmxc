import SwiftUI

struct ContentAreaView: View {
    @Environment(BrowserController.self) private var controller
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if let tab = controller.tabManager.selectedTab {
                content(for: tab)
            } else {
                StartPageView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(canvasColor)
        .overlay(alignment: .top) {
            loadingBar
        }
        .animation(.easeInOut(duration: 0.2), value: controller.selectedNavigation?.isLoading ?? false)
        .onChange(of: controller.tabManager.selectedTabID) { _, _ in
            controller.librarySection = nil
        }
    }

    private var canvasColor: Color {
        colorScheme == .dark ? .black : Color(nsColor: .windowBackgroundColor)
    }

    @ViewBuilder
    private var loadingBar: some View {
        let isLoading = controller.selectedNavigation?.isLoading ?? false
        if isLoading {
            TimelineView(.animation) { timeline in
                GeometryReader { geometry in
                    let period = 1.4
                    let t = timeline.date.timeIntervalSinceReferenceDate
                        .truncatingRemainder(dividingBy: period) / period
                    Capsule()
                        .fill(Color.accentColor)
                        .frame(width: geometry.size.width * 0.3, height: 2)
                        .offset(x: geometry.size.width * CGFloat(0.7 * t - 0.15))
                }
                .frame(height: 2)
            }
            .transition(.opacity)
        }
    }

    @ViewBuilder
    private func content(for tab: TabModel) -> some View {
        let navigation = tab.navigation
        if navigation.webContentCrashed {
            statusView(
                title: "This webpage quit unexpectedly",
                message: "Reload to try again."
            ) {
                Button("Reload") { tab.navigation.recoverFromCrash() }
                    .keyboardShortcut(.defaultAction)
            }
        } else if let loadError = navigation.loadError {
            statusView(
                title: "This webpage could not be loaded",
                message: loadError
            ) {
                Button("Try Again") { tab.navigation.reload() }
                    .keyboardShortcut(.defaultAction)
            }
        } else if navigation.hasCommittedNavigation || navigation.isLoading {
            WebViewContainer(webView: navigation.webView)
                .id(tab.id)
        } else {
            StartPageView()
        }
    }

    private func statusView<Actions: View>(
        title: String,
        message: String,
        @ViewBuilder actions: () -> Actions
    ) -> some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.headline)
            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            actions()
                .padding(.top, 6)
        }
        .padding(32)
        .frame(maxWidth: 400)
    }
}
