import SwiftUI

/// A faithful miniature of the real browser window: the floating command bar
/// and start page laid out at true size, then scaled down so proportions,
/// spacing and type match the app exactly.
struct OnboardingBrowserPreview: View {
    let engineName: String

    @Environment(\.colorScheme) private var colorScheme

    private static let canvasSize = CGSize(width: 1000, height: 650)
    private static let scale: CGFloat = 0.5

    var body: some View {
        window
            .frame(width: Self.canvasSize.width, height: Self.canvasSize.height)
            .scaleEffect(Self.scale)
            .frame(
                width: Self.canvasSize.width * Self.scale,
                height: Self.canvasSize.height * Self.scale
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Preview of the OPENMXC start page")
    }

    private var window: some View {
        ZStack(alignment: .top) {
            GlassCanvasBackground()

            startPage

            toolbar
                .padding(.top, 44)
                .padding(.horizontal, 24)

            trafficLights
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 16)
                .padding(.leading, 18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(Color.primary.opacity(colorScheme == .dark ? 0.18 : 0.1), lineWidth: 1)
        }
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.45 : 0.18), radius: 48, y: 28)
    }

    // MARK: - Window chrome

    private var trafficLights: some View {
        HStack(spacing: 8) {
            trafficLight(Color(red: 1.0, green: 0.37, blue: 0.34))
            trafficLight(Color(red: 1.0, green: 0.74, blue: 0.18))
            trafficLight(Color(red: 0.16, green: 0.78, blue: 0.25))
        }
    }

    private func trafficLight(_ color: Color) -> some View {
        Circle()
            .fill(color)
            .overlay(Circle().strokeBorder(.black.opacity(0.12), lineWidth: 0.5))
            .frame(width: 12, height: 12)
    }

    private var toolbar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 2) {
                toolbarIcon("chevron.left")
                toolbarIcon("chevron.right", dimmed: true)
                toolbarIcon("arrow.clockwise", dimmed: true)
            }

            groupDivider

            HStack(spacing: 9) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("Search or enter address")
                    .font(.body)
                    .foregroundStyle(.tertiary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .frame(height: 32)
            .glassEffect(.regular, in: .capsule)

            groupDivider

            HStack(spacing: 2) {
                toolbarIcon("star", dimmed: true)
                toolbarIcon("square.and.arrow.up", dimmed: true)
                toolbarIcon("books.vertical")
                toolbarIcon("book", dimmed: true)
                engineChip
                toolbarIcon(colorScheme == .dark ? "sun.max" : "moon")
                toolbarIcon("gearshape")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .glassEffect(.regular, in: .rect(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.4 : 0.12), radius: 16, y: 6)
    }

    private func toolbarIcon(_ symbol: String, dimmed: Bool = false) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(.secondary)
            .frame(width: 32, height: 32)
            .opacity(dimmed ? 0.35 : 1)
    }

    private var groupDivider: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.12))
            .frame(width: 1, height: 18)
    }

    private var engineChip: some View {
        HStack(spacing: 6) {
            Text(String(engineName.prefix(1)).uppercased())
                .font(.system(size: 9.5, weight: .bold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 16, height: 16)
                .background(Color.accentColor.opacity(0.14), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
            Text(engineName)
                .font(.system(size: 11, weight: .medium))
                .lineLimit(1)
            Image(systemName: "chevron.down")
                .font(.system(size: 7.5, weight: .bold))
                .foregroundStyle(.tertiary)
        }
        .foregroundStyle(.secondary)
        .padding(.leading, 5)
        .padding(.trailing, 10)
        .frame(height: 28)
        .background(Capsule().fill(Color.primary.opacity(0.05)))
        .overlay(Capsule().strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5))
        .padding(.horizontal, 2)
    }

    // MARK: - Start page

    private var startPage: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 30) {
                Image("OpenMxcLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 34, height: 34)

                Text(greeting)
                    .font(.system(size: 30, weight: .medium))
                    .tracking(-0.4)

                HStack(spacing: 9) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text("Search or enter address")
                        .font(.body)
                        .foregroundStyle(.tertiary)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 14)
                .frame(width: 560, height: 44)
                .glassEffect(.regular, in: .capsule)

                HStack(spacing: 30) {
                    ForEach(Self.sites) { site in
                        siteTile(site)
                    }
                }
            }
            .padding(.top, 40)

            Spacer()

            VStack(spacing: 6) {
                Text("“Simplicity is the ultimate sophistication.”")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Text("— Leonardo da Vinci")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.bottom, 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func siteTile(_ site: PreviewSite) -> some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.primary.opacity(colorScheme == .dark ? 0.07 : 0.03))
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.primary.opacity(colorScheme == .dark ? 0.16 : 0.09), lineWidth: 0.5)
                site.mark
                    .frame(width: 30, height: 30)
                    .background(site.background, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .frame(width: 56, height: 56)

            Text(site.title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(width: 84)
        }
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private struct PreviewSite: Identifiable {
        let title: String
        let background: Color
        let mark: AnyView

        var id: String { title }
    }

    private static func symbolMark(_ name: String, color: Color = .white, size: CGFloat = 15) -> AnyView {
        AnyView(
            Image(systemName: name)
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(color)
        )
    }

    private static func letterMark(_ letter: String, color: Color = .white, serif: Bool = false) -> AnyView {
        AnyView(
            Text(letter)
                .font(.system(size: 16, weight: .bold, design: serif ? .serif : .default))
                .foregroundStyle(color)
        )
    }

    private static let sites: [PreviewSite] = [
        PreviewSite(title: "apple.com", background: .black, mark: symbolMark("apple.logo")),
        PreviewSite(title: "github.com", background: Color(red: 0.14, green: 0.16, blue: 0.18), mark: symbolMark("chevron.left.forwardslash.chevron.right", size: 11)),
        PreviewSite(title: "wikipedia.org", background: .white, mark: letterMark("W", color: .black, serif: true)),
        PreviewSite(title: "youtube.com", background: Color(red: 1.0, green: 0.0, blue: 0.0), mark: symbolMark("play.fill", size: 12)),
        PreviewSite(title: "maps.apple.com", background: Color(red: 0.2, green: 0.72, blue: 0.4), mark: symbolMark("map.fill", size: 13)),
        PreviewSite(title: "nytimes.com", background: .white, mark: letterMark("T", color: .black, serif: true)),
    ]
}
