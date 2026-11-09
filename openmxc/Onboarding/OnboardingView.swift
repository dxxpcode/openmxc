import SwiftUI

/// First-run experience: a full-window overlay with a single glass card —
/// theme and search engine inline — instead of a multi-page wizard.
struct OnboardingView: View {
    let onComplete: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appTheme") private var appTheme = "system"
    @State private var engines: [SearchEngine] = []
    @State private var selectedEngineID = ""
    @State private var appeared = false

    var body: some View {
        ZStack {
            backdrop
            card
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

    private var backdrop: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial)
            Color.black.opacity(colorScheme == .dark ? 0.42 : 0.26)
        }
        .ignoresSafeArea()
    }

    private var card: some View {
        VStack(spacing: 0) {
            Spacer()

            Image("OpenMxcLogo")
                .resizable()
                .frame(width: 84, height: 84)
                .scaleEffect(appeared ? 1 : 0.8)
                .opacity(appeared ? 1 : 0)
                .animation(Motion.standard.delay(0.02), value: appeared)

            VStack(spacing: 6) {
                Text(BrowserConfiguration.applicationName)
                    .font(.system(size: 28, weight: .bold))
                    .tracking(-0.4)

                Text("A fast, private, native browser for macOS.\nNo accounts, no ads, no tracking.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
            .padding(.top, 20)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 8)
            .animation(Motion.standard.delay(0.08), value: appeared)

            VStack(alignment: .leading, spacing: 18) {
                preferenceSection(title: "Appearance") {
                    Picker("Appearance", selection: $appTheme) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(width: 240)
                }

                preferenceSection(title: "Search engine") {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4),
                        spacing: 10
                    ) {
                        ForEach(engines) { engine in
                            engineChip(engine)
                        }
                    }
                }
            }
            .padding(.top, 30)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)
            .animation(Motion.standard.delay(0.16), value: appeared)

            Button("Start browsing") { finish() }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .frame(minWidth: 180)
                .keyboardShortcut(.defaultAction)
                .padding(.top, 32)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
                .animation(Motion.standard.delay(0.24), value: appeared)

            Spacer()
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 36)
        .frame(maxWidth: .infinity, minHeight: 540, maxHeight: 540)
        .glassEffect(.regular, in: .rect(cornerRadius: 28, style: .continuous))
        .padding(.horizontal, 24)
    }

    private func preferenceSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 10.5, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(.tertiary)
            content()
        }
    }

    private func engineChip(_ engine: SearchEngine) -> some View {
        let isSelected = engine.id == selectedEngineID
        return Button {
            withAnimation(Motion.quick) { selectedEngineID = engine.id }
        } label: {
            HStack(spacing: 8) {
                Text(String(engine.name.prefix(1)).uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(isSelected ? Color.white : Color.accentColor)
                    .frame(width: 18, height: 18)
                    .background(
                        isSelected ? Color.accentColor : Color.accentColor.opacity(0.14),
                        in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                    )
                Text(engine.name)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? Color.white : .primary)
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background {
                Capsule().fill(isSelected ? Color.accentColor : Color.primary.opacity(0.05))
            }
            .overlay {
                Capsule().strokeBorder(
                    isSelected ? Color.accentColor.opacity(0.45) : Color.primary.opacity(0.08),
                    lineWidth: 0.5
                )
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Search engine: \(engine.name)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func finish() {
        if !selectedEngineID.isEmpty {
            SearchService.setDefaultEngine(id: selectedEngineID)
        }
        AppSettings.setBool("onboardingCompleted", true)
        onComplete()
    }
}
