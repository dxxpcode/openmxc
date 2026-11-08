import SwiftUI

struct MainWindowView: View {
    @Environment(BrowserController.self) private var controller

    var body: some View {
        VStack(spacing: 0) {
            BrowserToolbar()
            ContentAreaView()
        }
        .frame(
            minWidth: BrowserConstants.minimumWindowWidth,
            minHeight: BrowserConstants.minimumWindowHeight
        )
        .overlay {
            if controller.showTabSwitcher {
                TabSwitcherView()
            }
        }
        .overlay(alignment: .trailing) {
            if controller.showLibraryPanel {
                LibraryPanelView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.18), value: controller.showLibraryPanel)
    }
}
