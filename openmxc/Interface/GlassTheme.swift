import SwiftUI

/// Full-window Liquid Glass canvas: a frosted vibrancy surface with a soft
/// depth gradient, so glass chrome and cards refract real texture instead of
/// sitting on flat white/black. Web content stays opaque on top; only the
/// browser's own surfaces (start page, library, reader, error states) show it.
struct GlassCanvasBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial)
            LinearGradient(
                colors: gradientColors,
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var gradientColors: [Color] {
        if colorScheme == .dark {
            return [
                Color(red: 0.08, green: 0.09, blue: 0.16).opacity(0.65),
                Color(red: 0.02, green: 0.03, blue: 0.07).opacity(0.8)
            ]
        }
        return [
            Color(red: 0.72, green: 0.80, blue: 0.95).opacity(0.55),
            Color(red: 0.55, green: 0.66, blue: 0.88).opacity(0.6)
        ]
    }
}
