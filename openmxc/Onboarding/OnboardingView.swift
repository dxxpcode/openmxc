import SwiftUI

/// First-run experience: the full app window becomes one Liquid Glass surface
/// with Settings-style preference rows — icon tiles, hairline separators,
/// standard macOS form controls. No pages, no wizard.
struct OnboardingView: View {
    let onComplete: () -> Void
    @AppStorage("appTheme") private var appTheme = "system"
    @State private var engines: [SearchEngine] = []
    @State private var selectedEngineID = ""
    @State private var appeared = false

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

            preferenceRows
                .padding(.top, 36)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
                .animation(Motion.standard.delay(0.16), value: appeared)

            Button("Start browsing") { finish() }
                .buttonStyle(.glassProminent)
                .font(.system(size: 15, weight: .semibold))
                .frame(maxWidth: .infinity, minHeight: 46)
                .keyboardShortcut(.defaultAction)
                .padding(.top, 40)
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

    // MARK: - Settings-style rows

    private var preferenceRows: some View {
        VStack(spacing: 0) {
            preferenceRow(
                icon: "circle.lefthalf.filled",
                title: "Appearance",
                subtitle: "System, Light, or Dark"
            ) {
                Picker("Appearance", selection: $appTheme) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 220)
            }

            hairline

            preferenceRow(
                icon: "magnifyingglass",
                title: "Search engine",
                subtitle: currentEngineName
            ) {
                engineMenu
            }
        }
    }

    private func preferenceRow<Control: View>(
        icon: String,
        title: String,
        subtitle: String,
        @ViewBuilder control: () -> Control
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 30, height: 30)
                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13.5, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 20)

            control()
        }
        .frame(height: 56)
        .contentShape(Rectangle())
    }

    private var hairline: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.14))
            .frame(height: 0.5)
            .padding(.leading, 44)
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
            HStack(spacing: 6) {
                Text(currentEngineName)
                    .font(.system(size: 12.5, weight: .medium))
                    .lineLimit(1)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 12)
            .frame(height: 30)
            .background(Color.primary.opacity(0.06), in: Capsule())
            .overlay {
                Capsule().strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
            }
            .contentShape(Capsule())
        }
        .menuIndicator(.hidden)
        .fixedSize()
        .help("Search Engine")
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
