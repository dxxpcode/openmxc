import SwiftUI

struct MainWindowView: View {
    @Environment(BrowserController.self) private var controller
    @Binding var showAskPanel: Bool
    @Binding var showTabGroupsPanel: Bool

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
            if showAskPanel {
                AskPagePanel(onClose: { showAskPanel = false })
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .overlay(alignment: .bottom) {
            if showTabGroupsPanel {
                TabGroupsPanel(onClose: { showTabGroupsPanel = false })
                    .padding(.bottom, showAskPanel ? 320 : 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.35, bounce: 0.1), value: showAskPanel)
        .animation(.spring(duration: 0.35, bounce: 0.1), value: showTabGroupsPanel)
    }
}
