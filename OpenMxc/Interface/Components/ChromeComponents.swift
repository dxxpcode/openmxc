import SwiftUI

/// Toolbar-style icon button: secondary monochrome at rest, accent on hover/press.
/// Matches the quiet, monochrome look of Apple's browser toolbars.
struct ChromeIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(configuration.isPressed ? Color.accentColor : Color.secondary)
            .frame(width: 28, height: 28)
            .background {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(configuration.isPressed ? Color.accentColor.opacity(0.15) : .clear)
            }
            .contentShape(Rectangle())
    }
}

extension ButtonStyle where Self == ChromeIconButtonStyle {
    static var chromeIcon: ChromeIconButtonStyle { ChromeIconButtonStyle() }
}

/// Subtle rounded field used by the address bar and library search fields.
struct ChromeFieldModifier: ViewModifier {
    var isFocused: Bool = false

    func body(content: Content) -> some View {
        content
            .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(
                        isFocused ? Color.accentColor.opacity(0.6) : Color(nsColor: .separatorColor),
                        lineWidth: isFocused ? 1 : 0.5
                    )
            }
    }
}

extension View {
    func chromeField(isFocused: Bool = false) -> some View {
        modifier(ChromeFieldModifier(isFocused: isFocused))
    }
}
