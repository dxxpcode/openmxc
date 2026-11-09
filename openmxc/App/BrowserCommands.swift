import SwiftUI

struct BrowserCommands: Commands {
    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("New Tab") {
                NotificationCenter.default.post(name: .openmxcNewTab, object: nil)
            }
            .keyboardShortcut("t", modifiers: .command)

            Button("New Private Window") {
                NotificationCenter.default.post(name: .openmxcNewPrivateWindow, object: nil)
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])

            Button("Close Tab") {
                NotificationCenter.default.post(name: .openmxcCloseTab, object: nil)
            }
            .keyboardShortcut("w", modifiers: .command)

            Button("Close Window") {
                NotificationCenter.default.post(name: .openmxcCloseWindow, object: nil)
            }
            .keyboardShortcut("w", modifiers: [.command, .shift])
        }

        CommandGroup(after: .toolbar) {
            Button("Focus Address Bar") {
                NotificationCenter.default.post(name: .openmxcFocusAddressBar, object: nil)
            }
            .keyboardShortcut("l", modifiers: .command)

            Button("Toggle Sidebar") {
                NotificationCenter.default.post(name: .openmxcToggleSidebar, object: nil)
            }
            .keyboardShortcut("s", modifiers: [.control, .command])

            Button("Ask About This Page") {
                NotificationCenter.default.post(name: .openmxcAskPage, object: nil)
            }
            .keyboardShortcut("a", modifiers: [.command, .shift])

            Button("Command Palette") {
                NotificationCenter.default.post(name: .openmxcCommandPalette, object: nil)
            }
            .keyboardShortcut("k", modifiers: .command)

            Button("Toggle Zen Mode") {
                NotificationCenter.default.post(name: .openmxcToggleZenMode, object: nil)
            }
            .keyboardShortcut(".", modifiers: .command)

            Button("Toggle Reader Mode") {
                NotificationCenter.default.post(name: .openmxcToggleReaderMode, object: nil)
            }
            .keyboardShortcut("r", modifiers: [.command, .shift])
        }

        CommandGroup(after: .windowList) {
            Button("Minimize") {
                NotificationCenter.default.post(name: .openmxcMinimizeWindow, object: nil)
            }
            .keyboardShortcut("m", modifiers: .command)

            Button("Zoom") {
                NotificationCenter.default.post(name: .openmxcZoomWindow, object: nil)
            }
            .keyboardShortcut(.return, modifiers: .command)
        }

        CommandGroup(after: .sidebar) {
            Button("Add to Favorites") {
                NotificationCenter.default.post(name: .openmxcToggleFavorite, object: nil)
            }
            .keyboardShortcut("d", modifiers: .command)

            ForEach(1...9, id: \.self) { index in
                Button("Select Tab \(index)") {
                    NotificationCenter.default.post(
                        name: .openmxcSelectTabIndex,
                        object: nil,
                        userInfo: ["index": index - 1]
                    )
                }
                .keyboardShortcut(KeyEquivalent(Character("\(index)")), modifiers: .command)
            }

            Button("Show Next Tab") {
                NotificationCenter.default.post(name: .openmxcSelectAdjacentTab, object: nil, userInfo: ["direction": 1])
            }
            .keyboardShortcut("]", modifiers: [.command, .shift])

            Button("Show Previous Tab") {
                NotificationCenter.default.post(name: .openmxcSelectAdjacentTab, object: nil, userInfo: ["direction": -1])
            }
            .keyboardShortcut("[", modifiers: [.command, .shift])
        }
    }
}

extension Notification.Name {
    static let openmxcNewTab = Notification.Name("openmxc.newTab")
    static let openmxcNewPrivateWindow = Notification.Name("openmxc.newPrivateWindow")
    static let openmxcCloseTab = Notification.Name("openmxc.closeTab")
    static let openmxcCloseWindow = Notification.Name("openmxc.closeWindow")
    static let openmxcFocusAddressBar = Notification.Name("openmxc.focusAddressBar")
    static let openmxcToggleSidebar = Notification.Name("openmxc.toggleSidebar")
    static let openmxcSelectAdjacentTab = Notification.Name("openmxc.selectAdjacentTab")
    static let openmxcToggleFavorite = Notification.Name("openmxc.toggleFavorite")
    static let openmxcSelectTabIndex = Notification.Name("openmxc.selectTabIndex")
    static let openmxcAddressBarFocus = Notification.Name("openmxc.addressBarFocus")
    static let openmxcAskPage = Notification.Name("openmxc.askPage")
    static let openmxcCommandPalette = Notification.Name("openmxc.commandPalette")
    static let openmxcToggleZenMode = Notification.Name("openmxc.toggleZenMode")
    static let openmxcToggleReaderMode = Notification.Name("openmxc.toggleReaderMode")
    static let openmxcMinimizeWindow = Notification.Name("openmxc.minimizeWindow")
    static let openmxcZoomWindow = Notification.Name("openmxc.zoomWindow")
}
