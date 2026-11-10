import SwiftUI

/// First-run welcome: a full-window Liquid Glass overlay. Centered, minimal,
/// one action — logo, name, one line of value, two quiet preferences, and a
/// single glass CTA. Shown once; completion is persisted locally.
struct OnboardingView: View {
    let onComplete: () -> Void

    @AppStorage("appTheme") private var appTheme = "system"
    @State private var engines: [SearchEngine] = []
    @State private var selectedEngineID = ""
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            logo
                .padding(.bottom, 28)

            Text("OPENMXC")
                .font(.system(size: 54, weight: .bold))
                .tracking(-1.6)
                .foregroundStyle(.primary)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
                .animation(Motion.standard.delay(0.06), value: appeared)

            Text("A fast, private, native browser for macOS.")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .padding(.top, 10)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
                .animation(Motion.standard.delay(0.12), value: appeared)

            featureChips
                .padding(.top, 22)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
                .animation(Motion.standard.delay(0.18), value: appeared)

            preferences
                .padding(.top, 44)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
                .animation(Motion.standard.delay(0.24), value: appeared)

            Button("Start browsing") { finish() }
                .buttonStyle(.glassProminent)
                .font(.system(size: 15, weight: .semibold))
                .frame(maxWidth: .columnWidth, minHeight: 48)
                .keyboardShortcut(.defaultAction)
                .padding(.top, 28)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
                .animation(Motion.standard.delay(0.3), value: appeared)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(GlassCanvasBackground())
        .onAppear {
            engines = SearchService.allEngines()
            selectedEngineID = SearchService.defaultEngine.id
            if selectedEngineID.isEmpty, let first = engines.first {
                selectedEngineID = first.id
            }
            withAnimation(Motion.standard) { appeared = true }
        }
    }

    // MARK: - Logo

    private var logo: some View {
        Image("OpenMxcLogo")
            .resizable()
            .frame(width: 76, height: 76)
            .scaleEffect(appeared ? 1 : 0.82)
            .opacity(appeared ? 1 : 0)
            .background {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.accentColor.opacity(0.22), Color.accentColor.opacity(0)],
                            center: .center,
                            startRadius: 20,
                            endRadius: 90
                        )
                    )
                    .frame(width: 190, height: 190)
                    .blur(radius: 6)
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.7)
                    .animation(Motion.standard.delay(0.02), value: appeared)
            }
            .animation(Motion.standard.delay(0.02), value: appeared)
    }

    // MARK: - Value chips

    private var featureChips: some View {
        HStack(spacing: 10) {
            chip(icon: "lock.shield", text: "Private by design")
            chip(icon: "bolt.fill", text: "Native and fast")
            chip(icon: "person.crop.circle.badge.xmark", text: "No accounts")
        }
    }

    private func chip(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(Color.accentColor)
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Color.primary.opacity(0.05), in: Capsule())
        .overlay {
            Capsule().strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
        }
    }

    // MARK: - Preferences

    private var preferences: some View {
        VStack(spacing: 16) {
            preferenceRow(title: "Appearance") {
                Picker("Appearance", selection: $appTheme) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 220)
            }

            preferenceRow(title: "Search engine") {
                engineMenu
            }
        }
        .frame(maxWidth: .columnWidth)
    }

    private func preferenceRow<Control: View>(
        title: String,
        @ViewBuilder control: () -> Control
    ) -> some View {
        HStack(spacing: 14) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)
                .frame(width: 110, alignment: .leading)
            Spacer(minLength: 12)
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
                    .lineLimit(1)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 14)
            .frame(minWidth: 160, minHeight: 36)
            .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
            }
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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

    // MARK: - Completion

    private func finish() {
        if !selectedEngineID.isEmpty {
            SearchService.setDefaultEngine(id: selectedEngineID)
        }
        AppSettings.setBool("onboardingCompleted", true)
        onComplete()
    }
}

private extension CGFloat {
    /// Width of the centered onboarding column.
    static let columnWidth: CGFloat = 440
}
