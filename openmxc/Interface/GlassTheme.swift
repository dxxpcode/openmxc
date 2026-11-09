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
            return [Color(white: 0.10).opacity(0.55), Color.black.opacity(0.85)]
        }
        return [Color.white.opacity(0.65), Color(white: 0.90).opacity(0.85)]
    }
}
