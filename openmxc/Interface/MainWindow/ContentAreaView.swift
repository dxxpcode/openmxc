import SwiftUI

struct ContentAreaView: View {
    @Environment(BrowserController.self) private var controller

    var body: some View {
        Group {
            if let section = controller.librarySection {
                LibraryCanvasView(section: section)
            } else if let tab = controller.tabManager.selectedTab {
                content(for: tab)
            } else {
                StartPageView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(GlassCanvasBackground())
        .overlay(alignment: .top) {
            loadingBar
        }
        .animation(Motion.quick, value: controller.selectedNavigation?.isLoading ?? false)
        .onChange(of: controller.tabManager.selectedTabID) { _, _ in
            controller.librarySection = nil
        }
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
            ErrorStateView(
                symbol: "exclamationmark.triangle",
                title: "This webpage quit unexpectedly",
                message: "Reload to try again.",
                detail: nil,
                canGoBack: navigation.canGoBack,
                onRetry: { tab.navigation.recoverFromCrash() },
                onBack: { tab.navigation.goBack() }
            )
        } else if let failure = navigation.loadFailure {
            failureView(failure, navigation: navigation)
        } else if navigation.isReaderActive, let article = navigation.readerArticle {
            ReaderView(article: article, navigation: navigation)
        } else if navigation.hasCommittedNavigation || navigation.isLoading {
            WebViewContainer(webView: navigation.webView)
                .id(tab.id)
        } else {
            StartPageView()
        }
    }

    @ViewBuilder
    private func failureView(_ failure: LoadFailure, navigation: NavigationManager) -> some View {
        let content = failureContent(failure)
        ErrorStateView(
            symbol: content.symbol,
            title: content.title,
            message: content.message,
            detail: content.detail,
            canGoBack: navigation.canGoBack,
            onRetry: { navigation.reload() },
            onBack: { navigation.goBack() }
        )
    }

    private func failureContent(_ failure: LoadFailure) -> (symbol: String, title: String, message: String, detail: String?) {
        switch failure.kind {
        case .offline:
            return ("wifi.slash", "You're offline", "Check your internet connection, then try again.", nil)
        case .timedOut:
            return ("hourglass", "This page is taking too long", "The site didn't respond in time. Try again.", nil)
        case .unreachable:
            return ("globe", "This site can't be reached", "The server may be down, or the address may be wrong.", nil)
        case .generic:
            return ("exclamationmark.triangle", "This webpage could not be loaded", "Something went wrong while loading this page.", failure.detail)
        }
    }
}
