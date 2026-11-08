import AppKit
import SwiftUI
import WebKit

/// Samples a page's dominant color from a tiny snapshot so the chrome accent
/// can subtly follow the content. Returns nil for neutral pages (white, gray,
/// black) where tinting would be invisible or garish.
@MainActor
enum PageColorSampler {
    static func sample(webView: WKWebView) async -> Color? {
        let image: NSImage? = await withCheckedContinuation { continuation in
            webView.takeSnapshot(with: nil) { snapshot, _ in
                continuation.resume(returning: snapshot)
            }
        }
        guard let image else { return nil }
        return averageColor(of: image)
    }

    private static func averageColor(of image: NSImage) -> Color? {
        let pixelSize = 8
        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: pixelSize,
            pixelsHigh: pixelSize,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else { return nil }

        NSGraphicsContext.saveGraphicsState()
        let context = NSGraphicsContext(bitmapImageRep: rep)
        NSGraphicsContext.current = context
        image.draw(in: NSRect(x: 0, y: 0, width: pixelSize, height: pixelSize))
        NSGraphicsContext.restoreGraphicsState()

        guard let data = rep.bitmapData else { return nil }
        let pixelCount = pixelSize * pixelSize
        var red = 0.0
        var green = 0.0
        var blue = 0.0
        for index in 0..<pixelCount {
            let offset = index * 4
            red += Double(data[offset])
            green += Double(data[offset + 1])
            blue += Double(data[offset + 2])
        }

        let divisor = Double(pixelCount) * 255.0
        let redComponent = red / divisor
        let greenComponent = green / divisor
        let blueComponent = blue / divisor
        let average = NSColor(
            srgbRed: redComponent,
            green: greenComponent,
            blue: blueComponent,
            alpha: 1
        )

        let maxComponent = max(redComponent, greenComponent, blueComponent)
        let minComponent = min(redComponent, greenComponent, blueComponent)
        let delta = maxComponent - minComponent
        let saturation = maxComponent == 0 ? 0 : delta / maxComponent

        guard saturation > 0.18, maxComponent > 0.15, maxComponent < 0.92 else { return nil }
        return Color(nsColor: average)
    }
}
