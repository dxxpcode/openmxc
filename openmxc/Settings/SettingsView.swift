import SwiftUI

struct SettingsView: View {
    @AppStorage("appTheme") private var appTheme = "system"
    @State private var engines: [SearchEngine] = []
    @State private var defaultEngineID = ""
    @State private var trackingEnabled = true
    @State private var permissions: [(origin: String, type: PermissionManager.PermissionType, decision: PermissionManager.Decision)] = []

    var body: some View {
        TabView {
            generalTab.tabItem { Label("General", systemImage: "gear") }
            appearanceTab.tabItem { Label("Appearance", systemImage: "paintbrush") }
            privacyTab.tabItem { Label("Privacy", systemImage: "hand.raised") }
            downloadsTab.tabItem { Label("Downloads", systemImage: "arrow.down.circle") }
            aboutTab.tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 520, height: 420)
        .onAppear(perform: reload)
    }

    private var generalTab: some View {
        Form {
            Picker("Default search engine", selection: $defaultEngineID) {
                ForEach(engines) { engine in
                    Text(engine.name).tag(engine.id)
                }
            }
            .onChange(of: defaultEngineID) { _, newValue in
                SearchService.setDefaultEngine(id: newValue)
            }

        }
        .formStyle(.grouped)
        .padding(16)
    }

    private var appearanceTab: some View {
        Form {
            Picker("Theme", selection: $appTheme) {
                Text("System").tag("system")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
            }
            .pickerStyle(.segmented)
        }
        .formStyle(.grouped)
        .padding(16)
    }

    private var privacyTab: some View {
        Form {
            Toggle("Block known trackers", isOn: $trackingEnabled)
                .onChange(of: trackingEnabled) { _, newValue in
                    TrackingProtection.shared.setEnabled(newValue)
                }

            Section("Website permissions") {
                if permissions.isEmpty {
                    Text("No websites have been granted or denied permissions yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(permissions.enumerated()), id: \.offset) { _, entry in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(entry.origin).font(.body)
                                Text(entry.type.displayName).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(entry.decision == .allow ? "Allow" : "Deny")
                                .foregroundStyle(.secondary)
                            Button("Reset") {
                                PermissionManager.shared.reset(origin: entry.origin)
                                reload()
                            }
                            .controlSize(.small)
                        }
                    }
                }
            }

            Button("Clear Cookies and Website Data…") {
                clearWebsiteData()
            }
        }
        .formStyle(.grouped)
        .padding(16)
    }

    private var downloadsTab: some View {
        Form {
            LabeledContent("Download location") {
                Text(FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first?.path ?? "Downloads")
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Text("Downloads are saved to your Downloads folder and recorded in the Downloads library.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
        .padding(16)
    }

    private var aboutTab: some View {
        VStack(spacing: 12) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 64, height: 64)
            Text(BrowserConfiguration.applicationName).font(.title2.bold())
            Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                .foregroundStyle(.secondary)
            Text("A minimal, native macOS browser built on WebKit.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(16)
    }

    private func reload() {
        engines = SearchService.allEngines()
        defaultEngineID = SearchService.defaultEngine.id
        trackingEnabled = TrackingProtection.shared.isEnabled
        permissions = PermissionManager.shared.allDecisions()
    }

    private func clearWebsiteData() {
        let alert = NSAlert()
        alert.messageText = "Clear cookies and website data?"
        alert.informativeText = "This signs you out of websites and clears cached content. Bookmarks and history are not affected."
        alert.addButton(withTitle: "Clear")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        Task { await WebsiteDataManager.clearAllData() }
    }
}
