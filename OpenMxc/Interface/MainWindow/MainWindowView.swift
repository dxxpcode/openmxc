import SwiftUI

struct MainWindowView: View {
    @Environment(BrowserController.self) private var controller

    private var columnVisibility: Binding<NavigationSplitViewVisibility> {
        Binding(
            get: { controller.sidebarIsVisible ? .all : .detailOnly },
            set: { controller.sidebarIsVisible = $0 != .detailOnly }
        )
    }

    var body: some View {
        NavigationSplitView(columnVisibility: columnVisibility) {
            TabSidebarView()
        } detail: {
            VStack(spacing: 0) {
                loadingProgress
                ContentAreaView()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationSplitViewColumnWidth(
            min: BrowserConstants.sidebarMinimumWidth,
            ideal: BrowserConstants.sidebarDefaultWidth,
            max: BrowserConstants.sidebarMaximumWidth
        )
        .frame(
            minWidth: BrowserConstants.minimumWindowWidth,
            minHeight: BrowserConstants.minimumWindowHeight
        )
    }

    @ViewBuilder
    private var loadingProgress: some View {
        if let navigation = controller.selectedNavigation, navigation.isLoading {
            ProgressView(value: navigation.estimatedProgress)
                .progressViewStyle(.linear)
                .frame(height: 2)
        }
    }
}
