import SwiftUI

struct MainWindowView: View {
    @Environment(BrowserController.self) private var controller
    @Binding var showAskPanel: Bool

    var body: some View {
        HStack(spacing: 0) {
            if controller.sidebarIsVisible {
                TabRailView()
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
            VStack(spacing: 0) {
                BrowserToolbar()
                ContentAreaView()
            }
        }
        .frame(
            minWidth: BrowserConstants.minimumWindowWidth,
            minHeight: BrowserConstants.minimumWindowHeight
        )
        .overlay(alignment: .bottom) {
            if showAskPanel {
                AskPagePanel(onClose: { showAskPanel = false })
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.35, bounce: 0.1), value: showAskPanel)
        .animation(.easeInOut(duration: 0.2), value: controller.sidebarIsVisible)
    }
}
