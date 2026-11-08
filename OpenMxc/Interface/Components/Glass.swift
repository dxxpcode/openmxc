import SwiftUI

/// Tahoe-style quiet icon button: monochrome at rest, accent when pressed.
struct GlassIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(configuration.isPressed ? Color.accentColor : Color.secondary)
            .frame(width: 26, height: 26)
            .background {
                if configuration.isPressed {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Color.accentColor.opacity(0.18))
                }
            }
            .contentShape(Rectangle())
    }
}

extension ButtonStyle where Self == GlassIconButtonStyle {
    static var glassIcon: GlassIconButtonStyle { GlassIconButtonStyle() }
}

/// Floating capsule container for grouped toolbar controls.
struct GlassCapsule: ViewModifier {
    var cornerRadius: CGFloat = 14

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 4)
            .padding(.vertical, 3)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
            }
    }
}

extension View {
    func glassCapsule(cornerRadius: CGFloat = 14) -> some View {
        modifier(GlassCapsule(cornerRadius: cornerRadius))
    }
}

/// Rounded field style for address/search inputs.
struct GlassFieldModifier: ViewModifier {
    var isFocused: Bool = false
    var cornerRadius: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        isFocused ? Color.accentColor.opacity(0.55) : Color.primary.opacity(0.08),
                        lineWidth: isFocused ? 1 : 0.5
                    )
            }
    }
}

extension View {
    func glassField(isFocused: Bool = false, cornerRadius: CGFloat = 12) -> some View {
        modifier(GlassFieldModifier(isFocused: isFocused, cornerRadius: cornerRadius))
    }
}
