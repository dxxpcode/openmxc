import SwiftUI

/// Shared capsule search/address field used by the toolbar and the start page.
/// One chrome — leading icon, hairline border, accent focus ring with a soft
/// glow — at two sizes: compact in the toolbar, prominent on the start page.
struct SearchField: View {
    let placeholder: String
    @Binding var text: String
    var height: CGFloat = 32
    var icon: String = "magnifyingglass"
    var focus: FocusState<Bool>.Binding
    var onSubmit: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var isFocused: Bool { focus.wrappedValue }

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(.secondary)
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.body)
                .focused(focus)
                .onSubmit(onSubmit)
        }
        .padding(.horizontal, 14)
        .frame(height: height)
        .background { fieldBackground }
        .overlay {
            Capsule()
                .strokeBorder(borderColor, lineWidth: isFocused ? 1.2 : 0.5)
        }
        .shadow(
            color: isFocused ? Color.accentColor.opacity(colorScheme == .dark ? 0.3 : 0.18) : .clear,
            radius: isFocused ? 6 : 0
        )
        .animation(.easeInOut(duration: 0.15), value: isFocused)
    }

    /// Frosted capsule: vibrancy material with a light theme tint.
    private var fieldBackground: some View {
        ZStack {
            Capsule().fill(.regularMaterial)
            Capsule().fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white.opacity(0.3))
        }
    }

    private var borderColor: Color {
        isFocused
            ? Color.accentColor.opacity(colorScheme == .dark ? 0.65 : 0.55)
            : (colorScheme == .dark ? Color.primary.opacity(0.22) : Color(nsColor: .separatorColor))
    }
}
