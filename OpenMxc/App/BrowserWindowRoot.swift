import SwiftUI

struct BrowserWindowRoot: View {
    @State private var controller: BrowserController

    init(isPrivate: Bool = false) {
        _controller = State(initialValue: BrowserController(isPrivate: isPrivate))
    }

    var body: some View {
        MainWindowView()
            .environment(controller)
            .onDisappear {
                if !controller.isPrivate {
                    SessionStore.shared.unregister(controller)
                }
            }
    }
}
