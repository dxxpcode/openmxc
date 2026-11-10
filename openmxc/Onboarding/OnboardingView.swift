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
            Spacer()
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
        OnboardingBrowserPreview(engineName: currentEngineName)
            .environment(\.colorScheme, isDarkAppearance ? .dark : .light)
            .rotationEffect(.degrees(appeared ? 0 : 2))
            .scaleEffect(appeared ? 1 : 0.96)
            .opacity(appeared ? 1 : 0)
            .animation(Motion.standard.delay(0.16), value: appeared)
    }

    private var isDarkAppearance: Bool {
        appTheme == "dark" || (appTheme == "system" && colorScheme == .dark)
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

            Button { finish() } label: {
                HStack(spacing: 8) {
                    Text("Enter")
                        .font(.system(size: 14, weight: .semibold))
                    Image("OpenMxcLogo")
                        .renderingMode(.original)
                        .resizable()
                        .frame(width: 22, height: 22)
                }
            }
            .buttonStyle(.glass)
            .frame(width: 128, height: 42)
            .keyboardShortcut(.defaultAction)
            .help("Enter OPENMXC")
            .accessibilityLabel("Enter OPENMXC")
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
