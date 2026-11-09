import SwiftUI

/// Settings as a full-window Liquid Glass overlay inside the browser window:
/// section cards in a grid, each card a preference group with its controls
/// inline. Opened with ⌘,; closes with Esc or the close button.
struct SettingsView: View {
    var onClose: (() -> Void)? = nil

    @AppStorage("appTheme") private var appTheme = "system"
    @State private var engines: [SearchEngine] = []
    @State private var defaultEngineID = ""
    @State private var trackingEnabled = true
    @State private var permissions: [(origin: String, type: PermissionManager.PermissionType, decision: PermissionManager.Decision)] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if onClose != nil {
                    header
                        .padding(.top, 56)
                        .padding(.horizontal, 28)
                }
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 340, maximum: 560), spacing: 20)],
                    spacing: 20
                ) {
                    generalCard
                    appearanceCard
                    privacyCard
                    downloadsCard
                    aboutCard
                }
                .padding(.horizontal, 28)
                .padding(.top, onClose != nil ? 26 : 28)
                .padding(.bottom, 48)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(GlassCanvasBackground())
        .onAppear(perform: reload)
        .background { escapeHandler }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Settings")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.primary)
            Spacer()
            Button {
                onClose?()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.glass)
            .help("Close Settings")
            .accessibilityLabel("Close Settings")
        }
    }

    @ViewBuilder
    private var escapeHandler: some View {
        if let onClose {
            Button("") { onClose() }
                .keyboardShortcut(.escape, modifiers: [])
                .hidden()
        }
    }

    // MARK: - Cards

    private var generalCard: some View {
        SettingsCard(title: "General", icon: "gear") {
            settingsRow(title: "Default search engine", subtitle: "Used for searches from the address bar") {
                Picker("Default search engine", selection: $defaultEngineID) {
                    ForEach(engines) { engine in
                        Text(engine.name).tag(engine.id)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                .frame(width: 160)
                .onChange(of: defaultEngineID) { _, newValue in
                    SearchService.setDefaultEngine(id: newValue)
                }
            }
        }
    }

    private var appearanceCard: some View {
        SettingsCard(title: "Appearance", icon: "paintbrush") {
            settingsRow(title: "Theme", subtitle: "Follow the system or pick a mode") {
                Picker("Theme", selection: $appTheme) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 200)
            }
        }
    }

    private var privacyCard: some View {
        SettingsCard(title: "Privacy", icon: "hand.raised") {
            settingsRow(title: "Block known trackers", subtitle: "Stops tracker requests in web pages") {
                Toggle("Block known trackers", isOn: $trackingEnabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .onChange(of: trackingEnabled) { _, newValue in
                        TrackingProtection.shared.setEnabled(newValue)
                    }
            }

            if !permissions.isEmpty {
                hairline
                VStack(alignment: .leading, spacing: 10) {
                    Text("Website permissions")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(0.6)
                        .foregroundStyle(.secondary)
                    ForEach(Array(permissions.enumerated()), id: \.offset) { _, entry in
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.origin).font(.system(size: 12.5, weight: .medium)).lineLimit(1)
                                Text(entry.type.displayName).font(.system(size: 11)).foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 8)
                            Text(entry.decision == .allow ? "Allow" : "Deny")
                                .font(.system(size: 11.5))
                                .foregroundStyle(.secondary)
                            Button("Reset") {
                                PermissionManager.shared.reset(origin: entry.origin)
                                reload()
                            }
                            .controlSize(.small)
                        }
                    }
                }
                .padding(.top, 4)
            }

            hairline
            Button("Clear Cookies and Website Data…") {
                clearWebsiteData()
            }
            .controlSize(.small)
        }
    }

    private var downloadsCard: some View {
        SettingsCard(title: "Downloads", icon: "arrow.down.circle") {
            settingsRow(title: "Location", subtitle: "Where downloads are saved") {
                Text(FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first?.lastPathComponent ?? "Downloads")
                    .font(.system(size: 12.5))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: 160, alignment: .trailing)
            }
            Text("Downloads are saved to your Downloads folder and recorded in the Downloads library.")
                .font(.system(size: 11.5))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var aboutCard: some View {
        SettingsCard(title: "About", icon: "info.circle") {
            HStack(spacing: 14) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(BrowserConfiguration.applicationName)
                        .font(.system(size: 14, weight: .semibold))
                    Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            Text("A minimal, native macOS browser built on WebKit.")
                .font(.system(size: 11.5))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Building blocks

    private func settingsRow<Control: View>(
        title: String,
        subtitle: String,
        @ViewBuilder control: () -> Control
    ) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 12)
            control()
        }
    }

    private var hairline: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.1))
            .frame(height: 0.5)
            .padding(.vertical, 12)
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

private struct SettingsCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                Spacer(minLength: 0)
            }
            content
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 190, alignment: .topLeading)
        .glassEffect(.regular, in: .rect(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
    }
}
