import SwiftUI

@main
struct BrowserApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup(id: BrowserConstants.mainWindowID) {
            BrowserWindowRoot()
        }
        .defaultSize(width: BrowserConstants.defaultWindowWidth, height: BrowserConstants.defaultWindowHeight)
        .windowResizability(.contentMinSize)
        .windowStyle(.hiddenTitleBar)
        .commands { BrowserCommands() }

        WindowGroup(id: BrowserConstants.privateWindowID) {
            BrowserWindowRoot(isPrivate: true)
        }
        .defaultSize(width: BrowserConstants.defaultWindowWidth, height: BrowserConstants.defaultWindowHeight)
        .windowResizability(.contentMinSize)
        .windowStyle(.hiddenTitleBar)
    }
}
