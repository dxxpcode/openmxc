import SwiftUI

/// First-run experience: a single glass card with the essentials inline —
/// theme and search engine — instead of a multi-page wizard.
struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appTheme") private var appTheme = "system"
    @State private var engines: [SearchEngine] = []
    @State private var selectedEngineID = ""
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            Image("OpenMxcLogo")
                .resizable()
                .frame(width: 88, height: 88)
                .scaleEffect(appeared ? 1 : 0.85)
                .opacity(appeared ? 1 : 0)

            Text(BrowserConfiguration.applicationName)
                .font(.system(size: 30, weight: .bold))
                .padding(.top, 18)

            Text("A fast, private, native browser for macOS.\nNo accounts, no ads, no tracking.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.top, 8)

            VStack(alignment: .leading, spacing: 14) {
                preferenceRow(title: "Appearance") {
                    Picker("Appearance", selection: $appTheme) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(width: 210)
                }

                preferenceRow(title: "Search engine") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(engines) { engine in
                                engineChip(engine)
                            }
                        }
                    }
                }
            }
            .padding(.top, 26)

            Button("Start browsing") { finish() }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .padding(.top, 30)

            Spacer()
        }
        .frame(width: 540, height: 520)
        .padding(28)
        .glassEffect(.regular, in: .rect(cornerRadius: 28, style: .continuous))
        .padding(24)
        .onAppear {
            engines = SearchService.allEngines()
            selectedEngineID = SearchService.defaultEngine.id
            if selectedEngineID.isEmpty, let first = engines.first {
                selectedEngineID = first.id
            }
            withAnimation(Motion.standard.delay(0.08)) { appeared = true }
        }
    }

    private func preferenceRow<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 90, alignment: .leading)
            content()
            Spacer(minLength: 0)
        }
    }

    private func engineChip(_ engine: SearchEngine) -> some View {
        let isSelected = engine.id == selectedEngineID
        return Button {
            withAnimation(Motion.quick) { selectedEngineID = engine.id }
        } label: {
            HStack(spacing: 6) {
                Text(String(engine.name.prefix(1)).uppercased())
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundStyle(isSelected ? Color.white : Color.accentColor)
                    .frame(width: 16, height: 16)
                    .background(
                        isSelected ? Color.accentColor : Color.accentColor.opacity(0.14),
                        in: RoundedRectangle(cornerRadius: 5, style: .continuous)
                    )
                Text(engine.name)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
            }
            .foregroundStyle(isSelected ? Color.white : .secondary)
            .padding(.horizontal, 10)
            .frame(height: 28)
            .background {
                Capsule().fill(isSelected ? Color.accentColor.opacity(0.9) : Color.primary.opacity(0.05))
            }
            .overlay {
                Capsule().strokeBorder(
                    isSelected ? Color.accentColor.opacity(0.4) : Color.primary.opacity(0.08),
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
        dismiss()
    }
}
