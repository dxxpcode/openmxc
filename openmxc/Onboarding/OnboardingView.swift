import SwiftUI

/// First-run experience: a full-window overlay split into a brand panel and a
/// preferences panel — modern, calm, no wizard.
struct OnboardingView: View {
    let onComplete: () -> Void
    @AppStorage("appTheme") private var appTheme = "system"
    @State private var engines: [SearchEngine] = []
    @State private var selectedEngineID = ""
    @State private var appeared = false

    var body: some View {
        HStack(spacing: 0) {
            brandPanel
            verticalHairline
            controlsPanel
        }
        .padding(.horizontal, 72)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .glassEffect(.regular, in: .rect(cornerRadius: 0))
        .onAppear {
            engines = SearchService.allEngines()
            selectedEngineID = SearchService.defaultEngine.id
            if selectedEngineID.isEmpty, let first = engines.first {
                selectedEngineID = first.id
            }
            withAnimation(Motion.standard) { appeared = true }
        }
    }

    // MARK: - Brand panel

    private var brandPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            Image("OpenMxcLogo")
                .resizable()
                .frame(width: 64, height: 64)
                .scaleEffect(appeared ? 1 : 0.85)
                .opacity(appeared ? 1 : 0)
                .animation(Motion.standard.delay(0.02), value: appeared)

            Text("Welcome to\nOPENMXC")
                .font(.system(size: 40, weight: .bold))
                .tracking(-0.8)
                .lineSpacing(2)
                .padding(.top, 24)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
                .animation(Motion.standard.delay(0.08), value: appeared)

            Text("A fast, private, native browser for macOS.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .padding(.top, 12)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 8)
                .animation(Motion.standard.delay(0.14), value: appeared)

            VStack(alignment: .leading, spacing: 18) {
                featureRow(icon: "lock.shield", title: "Private by design", detail: "No accounts, no tracking, no ads")
                featureRow(icon: "bolt.fill", title: "Fast and native", detail: "Built on WebKit, tuned for macOS")
                featureRow(icon: "sparkles", title: "Yours alone", detail: "Everything stays on this Mac")
            }
            .padding(.top, 40)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)
            .animation(Motion.standard.delay(0.2), value: appeared)

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.trailing, 56)
    }

    private func featureRow(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 32, height: 32)
                .background(Color.accentColor.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13.5, weight: .semibold))
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Controls panel

    private var controlsPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()

            Text("Make it yours")
                .font(.system(size: 22, weight: .bold))
                .tracking(-0.3)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 8)
                .animation(Motion.standard.delay(0.1), value: appeared)

            Text("Two quick choices — change them anytime in Settings.")
                .font(.system(size: 12.5))
                .foregroundStyle(.secondary)
                .padding(.top, 6)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 8)
                .animation(Motion.standard.delay(0.14), value: appeared)

            VStack(spacing: 20) {
                preferenceBlock(title: "Appearance") {
                    Picker("Appearance", selection: $appTheme) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                preferenceBlock(title: "Search engine") {
                    engineMenu
                }
            }
            .padding(.top, 32)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)
            .animation(Motion.standard.delay(0.2), value: appeared)

            Button("Start browsing") { finish() }
                .buttonStyle(.glassProminent)
                .font(.system(size: 15, weight: .semibold))
                .frame(maxWidth: .infinity, minHeight: 46)
                .keyboardShortcut(.defaultAction)
                .padding(.top, 40)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
                .animation(Motion.standard.delay(0.26), value: appeared)

            Spacer()
        }
        .frame(width: 420, alignment: .leading)
    }

    private func preferenceBlock<Control: View>(title: String, @ViewBuilder control: () -> Control) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.7)
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
            HStack {
                Text(currentEngineName)
                    .font(.system(size: 13, weight: .medium))
                Spacer(minLength: 0)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .foregroundStyle(.primary)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 40)
            .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
            }
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .menuIndicator(.hidden)
        .fixedSize(horizontal: false, vertical: true)
        .help("Search Engine")
        .accessibilityLabel("Search Engine")
    }

    private var currentEngineName: String {
        engines.first { $0.id == selectedEngineID }?.name
            ?? SearchService.defaultEngine.name
    }

    private var verticalHairline: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.1))
            .frame(width: 0.5)
            .padding(.vertical, 80)
    }

    private func finish() {
        if !selectedEngineID.isEmpty {
            SearchService.setDefaultEngine(id: selectedEngineID)
        }
        AppSettings.setBool("onboardingCompleted", true)
        onComplete()
    }
}
