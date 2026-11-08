import SwiftUI

struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appTheme") private var appTheme = "system"
    @State private var page = 0
    @State private var engines: [SearchEngine] = []
    @State private var selectedEngineID = ""

    private let pageCount = 3

    var body: some View {
        VStack(spacing: 20) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .animation(.easeInOut(duration: 0.2), value: page)

            HStack(spacing: 8) {
                ForEach(0..<pageCount, id: \.self) { index in
                    Circle()
                        .fill(index == page ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }

            HStack {
                if page > 0 {
                    Button("Back") { page -= 1 }
                }
                Spacer()
                Button("Skip") { finish() }
                    .foregroundStyle(.secondary)
                Button(page == pageCount - 1 ? "Finish" : "Continue") {
                    if page == pageCount - 1 {
                        finish()
                    } else {
                        page += 1
                    }
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .frame(width: 520, height: 460)
        .onAppear {
            engines = SearchService.allEngines()
            selectedEngineID = SearchService.defaultEngine.id
            if selectedEngineID.isEmpty, let first = engines.first {
                selectedEngineID = first.id
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch page {
        case 0: welcomePage
        case 1: preferencesPage
        default: readyPage
        }
    }


    private var welcomePage: some View {
        VStack(spacing: 16) {
            Image("OpenMxcLogo")
                .resizable()
                .frame(width: 96, height: 96)
            Text(BrowserConfiguration.applicationName).font(.largeTitle.bold())
            Text("A fast, private, native browser for macOS.\nNo accounts, no ads, no tracking.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    private var preferencesPage: some View {
        Form {
            Picker("Default search engine", selection: $selectedEngineID) {
                ForEach(engines) { engine in
                    Text(engine.name).tag(engine.id)
                }
            }
            Picker("Appearance", selection: $appTheme) {
                Text("System").tag("system")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
            }
            .pickerStyle(.segmented)
        }
        .formStyle(.grouped)
        .padding()
    }

    private var readyPage: some View {
        VStack(spacing: 16) {
            Image(systemName: "globe")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
            Text("Ready to browse").font(.title2.bold())
            Text("Type an address or search in the toolbar, or pick a favorite from the start page.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    private func finish() {
        if !selectedEngineID.isEmpty {
            SearchService.setDefaultEngine(id: selectedEngineID)
        }
        AppSettings.setBool("onboardingCompleted", true)
        dismiss()
    }
}
