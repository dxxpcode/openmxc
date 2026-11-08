import SwiftUI

struct MainWindowView: View {
    @Environment(BrowserController.self) private var controller
    @Binding var showAskPanel: Bool

    var body: some View {
        ZStack(alignment: .top) {
            ContentAreaView()
            BrowserToolbar()
                .padding(.top, 12)
                .padding(.horizontal, 24)
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
    }
}
