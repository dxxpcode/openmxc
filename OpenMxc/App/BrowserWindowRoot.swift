import SwiftUI

struct BrowserWindowRoot: View {
    @State private var controller = BrowserController()

    var body: some View {
        MainWindowView()
            .environment(controller)
            .onDisappear {
                SessionStore.shared.unregister(controller)
            }
    }
}
