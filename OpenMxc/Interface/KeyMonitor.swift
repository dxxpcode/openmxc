import SwiftUI
import AppKit

/// Installs a local NSEvent key-down monitor while it is in a window, and
/// forwards events to `onKeyDown`. Return true from the closure to consume
/// the event. Used for arrow-key handling that SwiftUI's `onKeyPress` and
/// plain-key `keyboardShortcut`s do not deliver while a text field is
/// focused on macOS.
struct KeyMonitor: NSViewRepresentable {
    /// Receives the key-down event; return true to consume it.
    var onKeyDown: (NSEvent) -> Bool

    /// Only consume events while a text field (the field editor) has focus,
    /// so web content and other controls keep their normal key handling.
    var requiresTextFocus = true

    func makeNSView(context: Context) -> MonitorView {
        let view = MonitorView()
        view.onKeyDown = onKeyDown
        view.requiresTextFocus = requiresTextFocus
        return view
    }

    func updateNSView(_ nsView: MonitorView, context: Context) {
        nsView.onKeyDown = onKeyDown
        nsView.requiresTextFocus = requiresTextFocus
    }

    final class MonitorView: NSView {
        var onKeyDown: ((NSEvent) -> Bool)?
        var requiresTextFocus = true
        private var monitor: Any?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if window != nil {
                guard monitor == nil else { return }
                monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                    guard let self, let window = self.window, event.window == window else { return event }
                    if self.requiresTextFocus {
                        // Field editors are NSTextView instances. Anything else
                        // (web content, buttons) keeps the event.
                        guard window.firstResponder is NSTextView else { return event }
                    }
                    guard let handler = self.onKeyDown else { return event }
                    return handler(event) ? nil : event
                }
            } else if let monitor {
                NSEvent.removeMonitor(monitor)
                self.monitor = nil
            }
        }
    }
}
