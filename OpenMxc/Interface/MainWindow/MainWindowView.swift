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
        .overlay(alignment: .bottom) {
            if controller.showTabDock {
                TabDockView()
            }
        }
    }
}
