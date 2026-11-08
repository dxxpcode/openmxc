import SwiftUI

struct MainWindowView: View {
    @Environment(BrowserController.self) private var controller

    var body: some View {
        HStack(spacing: 0) {
            if controller.sidebarIsVisible {
                TabSidebarView()
                    .frame(width: controller.sidebarWidth)
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }

            Divider()

            VStack(spacing: 0) {
                BrowserToolbar()
                loadingProgress
                Divider()
                ContentAreaView()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(
            minWidth: BrowserConstants.minimumWindowWidth,
            minHeight: BrowserConstants.minimumWindowHeight
        )
    }

    @ViewBuilder
    private var loadingProgress: some View {
        if controller.navigation.isLoading {
            ProgressView(value: controller.navigation.estimatedProgress)
                .progressViewStyle(.linear)
                .frame(height: 2)
        }
    }
}
