import SwiftUI

/// OPENMXC custom dark design system — developer-tool aesthetic.
enum OX {
    static let background = Color(nsColor: NSColor(srgbRed: 0x10/255, green: 0x12/255, blue: 0x16/255, alpha: 1))
    static let surface = Color(nsColor: NSColor(srgbRed: 0x16/255, green: 0x19/255, blue: 0x1F/255, alpha: 1))
    static let surfaceRaised = Color(nsColor: NSColor(srgbRed: 0x1C/255, green: 0x21/255, blue: 0x28/255, alpha: 1))
    static let border = Color(nsColor: NSColor(srgbRed: 0x2A/255, green: 0x2F/255, blue: 0x3A/255, alpha: 1))
    static let accent = Color(nsColor: NSColor(srgbRed: 0x22/255, green: 0xD3/255, blue: 0xEE/255, alpha: 1))
    static let textPrimary = Color(nsColor: NSColor(srgbRed: 0xE6/255, green: 0xE9/255, blue: 0xEF/255, alpha: 1))
    static let textSecondary = Color(nsColor: NSColor(srgbRed: 0x8B/255, green: 0x93/255, blue: 0xA3/255, alpha: 1))
    static let textMuted = Color(nsColor: NSColor(srgbRed: 0x5C/255, green: 0x64/255, blue: 0x73/255, alpha: 1))

    static let mono = Font.system(.caption, design: .monospaced)
    static let monoSmall = Font.system(.caption2, design: .monospaced)

    static func mono(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .monospaced).weight(weight)
    }
}

struct OXIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(configuration.isPressed ? OX.accent : OX.textSecondary)
            .frame(width: 26, height: 24)
            .background(configuration.isPressed ? OX.surfaceRaised : .clear)
            .overlay(alignment: .bottom) {
                if configuration.isPressed {
                    Rectangle().fill(OX.accent).frame(height: 1)
                }
            }
            .contentShape(Rectangle())
    }
}

extension ButtonStyle where Self == OXIconButtonStyle {
    static var oxIcon: OXIconButtonStyle { OXIconButtonStyle() }
}

struct OXFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(OX.mono(.callout))
            .foregroundStyle(OX.textPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(OX.surface, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(OX.border, lineWidth: 1)
            }
    }
}

extension View {
    func oxField() -> some View { modifier(OXFieldStyle()) }
}
