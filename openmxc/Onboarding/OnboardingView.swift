import SwiftUI

/// First-run welcome: an edge-to-edge editorial overlay with a live browser
/// preview and a compact setup dock. It intentionally avoids wizard pages,
/// centered cards, and generic feature-chip layouts.
struct OnboardingView: View {
    let onComplete: () -> Void

    @AppStorage("appTheme") private var appTheme = "system"
    @Environment(\.colorScheme) private var colorScheme
    @State private var engines: [SearchEngine] = []
    @State private var selectedEngineID = ""
    @State private var appeared = false

    var body: some View {
        ZStack {
            GlassCanvasBackground()

            VStack(spacing: 0) {
                topBar

                HStack(alignment: .center, spacing: 72) {
                    editorialCopy
                    browserPreview
                }
                .frame(maxWidth: 1080)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 72)

                setupDock
                    .padding(.horizontal, 48)
                    .padding(.bottom, 36)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            engines = SearchService.allEngines()
            selectedEngineID = SearchService.defaultEngine.id
            if selectedEngineID.isEmpty, let first = engines.first {
                selectedEngineID = first.id
            }
            withAnimation(Motion.standard) { appeared = true }
        }
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            Image("OpenMxcLogo")
                .resizable()
                .frame(width: 22, height: 22)
            Text("OPENMXC")
                .font(.system(size: 12, weight: .bold))
                .tracking(1.2)
            Spacer()
            Text("FIRST RUN")
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.4)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 32)
        .padding(.top, 24)
        .opacity(appeared ? 1 : 0)
        .animation(Motion.quick, value: appeared)
    }

    private var editorialCopy: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("A quieter way\nto browse.")
                .font(.system(size: 58, weight: .bold, design: .rounded))
                .tracking(-2.8)
                .lineSpacing(-4)
                .foregroundStyle(.primary)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 18)
                .animation(Motion.standard.delay(0.06), value: appeared)

            Text("OPENMXC keeps the web fast, focused, and yours — with native macOS performance and privacy built in.")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .lineSpacing(3)
                .frame(maxWidth: 360, alignment: .leading)
                .padding(.top, 24)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 14)
                .animation(Motion.standard.delay(0.12), value: appeared)

            HStack(spacing: 8) {
                Image(systemName: "checkmark")
                Text("Ready in seconds")
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Color.accentColor)
            .padding(.top, 32)
            .opacity(appeared ? 1 : 0)
            .animation(Motion.standard.delay(0.18), value: appeared)
        }
        .frame(maxWidth: 430, alignment: .leading)
    }

    private var browserPreview: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Circle().fill(Color.red.opacity(0.7)).frame(width: 7, height: 7)
                Circle().fill(Color.yellow.opacity(0.7)).frame(width: 7, height: 7)
                Circle().fill(Color.green.opacity(0.7)).frame(width: 7, height: 7)
                Spacer()
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.primary.opacity(0.08))
                    .frame(width: 170, height: 16)
                Spacer()
            }
            .padding(.horizontal, 14)
            .frame(height: 34)
            .background(Color.primary.opacity(0.035))

            VStack(spacing: 0) {
                Image("OpenMxcLogo")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .padding(.bottom, 14)
                Text("Good afternoon")
                    .font(.system(size: 18, weight: .semibold))
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.primary.opacity(0.08))
                    .frame(width: 230, height: 28)
                    .overlay(alignment: .leading) {
                        HStack(spacing: 7) {
                            Image(systemName: "magnifyingglass")
                            Text("Search or enter address")
                        }
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 11)
                    }
                    .padding(.top, 16)
                HStack(spacing: 12) {
                    previewTile(symbol: "apple.logo")
                    previewTile(symbol: "globe")
                    previewTile(symbol: "star")
                }
                .padding(.top, 22)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(previewSurface)
        }
        .frame(width: 430, height: 292)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.16), radius: 28, y: 16)
        .rotationEffect(.degrees(appeared ? 0 : 2))
        .scaleEffect(appeared ? 1 : 0.96)
        .opacity(appeared ? 1 : 0)
        .animation(Motion.standard.delay(0.16), value: appeared)
    }

    private func previewTile(symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 11, weight: .medium))
            .frame(width: 42, height: 38)
            .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 9))
    }

    private var previewSurface: some ShapeStyle {
        let dark = appTheme == "dark" || (appTheme == "system" && colorScheme == .dark)
        return dark
            ? AnyShapeStyle(Color.black.opacity(0.24))
            : AnyShapeStyle(Color.white.opacity(0.25))
    }

    private var setupDock: some View {
        HStack(spacing: 0) {
            setupGroup(title: "APPEARANCE") {
                Picker("Appearance", selection: $appTheme) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 220)
            }

            Rectangle()
                .fill(Color.primary.opacity(0.1))
                .frame(width: 0.5, height: 34)
                .padding(.horizontal, 24)

            setupGroup(title: "SEARCH ENGINE") {
                engineMenu
            }

            Spacer(minLength: 28)

            Button("Enter OPENMXC") { finish() }
                .buttonStyle(.glassProminent)
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 160, height: 42)
                .keyboardShortcut(.defaultAction)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 16)
        .frame(maxWidth: 980)
        .background(Color.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 16)
        .animation(Motion.standard.delay(0.24), value: appeared)
    }

    private func setupGroup<Control: View>(
        title: String,
        @ViewBuilder control: () -> Control
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 9, weight: .bold))
                .tracking(1.1)
                .foregroundStyle(.secondary)
            control()
        }
    }

    private var engineMenu: some View {
        Menu {
            ForEach(engines) { engine in
                Button {
                    withAnimation(Motion.quick) { selectedEngineID = engine.id }
                } label: {
                    if engine.id == selectedEngineID {
                        Label(engine.name, systemImage: "checkmark")
                    } else {
                        Text(engine.name)
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                Text(currentEngineName)
                    .font(.system(size: 13, weight: .medium))
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 13)
            .frame(width: 160, height: 30, alignment: .leading)
            .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .menuIndicator(.hidden)
        .fixedSize()
        .accessibilityLabel("Search Engine")
    }

    private var currentEngineName: String {
        engines.first { $0.id == selectedEngineID }?.name
            ?? SearchService.defaultEngine.name
    }

    private func finish() {
        if !selectedEngineID.isEmpty {
            SearchService.setDefaultEngine(id: selectedEngineID)
        }
        AppSettings.setBool("onboardingCompleted", true)
        onComplete()
    }
}
