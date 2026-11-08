import SwiftUI

@main
struct BrowserApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var controller = BrowserController()

    var body: some Scene {
        WindowGroup(id: BrowserConstants.mainWindowID) {
            MainWindowView()
                .environment(controller)
        }
        .defaultSize(width: BrowserConstants.defaultWindowWidth, height: BrowserConstants.defaultWindowHeight)
        .windowResizability(.contentMinSize)
    }
}
