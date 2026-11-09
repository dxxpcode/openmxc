import SwiftUI

/// First-run experience: the full app window becomes one Liquid Glass surface
/// with the essentials inline — theme and search engine — no pages, no wizard.
struct OnboardingView: View {
    let onComplete: () -> Void
    @AppStorage("appTheme") private var appTheme = "system"
    @State private var engines: [SearchEngine] = []
    @State private var selectedEngineID = ""
    @State private var appeared = false
    @Namespace private var themeSelection

    var body: some View {
        card
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

            VStack(alignment: .leading, spacing: 22) {
                preferenceSection(title: "Appearance") {
                    themePicker
                }

                preferenceSection(title: "Search engine") {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4),
                        spacing: 12
                    ) {
                        ForEach(engines) { engine in
                            engineCard(engine)
                        }
                    }
                }
            }
            .padding(.top, 32)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)
            .animation(Motion.standard.delay(0.16), value: appeared)

            Button("Start browsing") { finish() }
                .buttonStyle(.glassProminent)
                .font(.system(size: 15, weight: .semibold))
                .frame(maxWidth: .infinity, minHeight: 46)
                .keyboardShortcut(.defaultAction)
                .padding(.top, 36)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
                .animation(Motion.standard.delay(0.24), value: appeared)

            Spacer()
        }
        .padding(.horizontal, 56)
        .padding(.vertical, 48)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .glassEffect(.regular, in: .rect(cornerRadius: 0))
    }

    // MARK: - Controls

    private var themePicker: some View {
        HStack(spacing: 4) {
            ForEach(themeOptions, id: \.value) { option in
                let isSelected = appTheme == option.value
                Button {
                    withAnimation(Motion.quick) { appTheme = option.value }
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: option.symbol)
                            .font(.system(size: 12, weight: .medium))
                        Text(option.title)
                            .font(.system(size: 12.5, weight: isSelected ? .semibold : .medium))
                    }
                    .foregroundStyle(isSelected ? Color.primary : Color.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 32)
                    .background {
                        if isSelected {
                            Capsule()
                                .fill(Color.primary.opacity(0.1))
                                .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
                                .matchedGeometryEffect(id: "themeSelection", in: themeSelection)
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Appearance: \(option.title)")
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(4)
        .background(Color.primary.opacity(0.05), in: Capsule())
        .overlay {
            Capsule().strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
        }
        .frame(width: 300)
    }

    private var themeOptions: [(symbol: String, title: String, value: String)] {
        [
            ("circle.lefthalf.filled", "System", "system"),
            ("sun.max", "Light", "light"),
            ("moon", "Dark", "dark"),
        ]
    }

    private func engineCard(_ engine: SearchEngine) -> some View {
        let isSelected = engine.id == selectedEngineID
        return Button {
            withAnimation(Motion.quick) { selectedEngineID = engine.id }
        } label: {
            HStack(spacing: 12) {
                Text(String(engine.name.prefix(1)).uppercased())
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(isSelected ? Color.white : Color.accentColor)
                    .frame(width: 30, height: 30)
                    .background(
                        isSelected ? Color.white.opacity(0.22) : Color.accentColor.opacity(0.14),
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                    )
                VStack(alignment: .leading, spacing: 1) {
                    Text(engine.name)
                        .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                        .lineLimit(1)
                    Text("Search")
                        .font(.system(size: 10.5))
                        .foregroundStyle(isSelected ? Color.white.opacity(0.75) : Color.secondary)
                }
                Spacer(minLength: 0)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .foregroundStyle(isSelected ? Color.white : .primary)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? Color.accentColor : Color.primary.opacity(0.05))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        isSelected ? Color.accentColor.opacity(0.5) : Color.primary.opacity(0.08),
                        lineWidth: 0.5
                    )
            }
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Search engine: \(engine.name)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func preferenceSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.system(size: 10.5, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(.tertiary)
            content()
        }
    }

    private func finish() {
        if !selectedEngineID.isEmpty {
            SearchService.setDefaultEngine(id: selectedEngineID)
        }
        AppSettings.setBool("onboardingCompleted", true)
        onComplete()
    }
}
