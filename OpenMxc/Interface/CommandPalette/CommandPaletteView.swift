import SwiftUI

/// ⌘K command palette: jump to open tabs, revisit history or favorites, and
/// run browser actions — all from one quiet, keyboard-first panel.
struct CommandPaletteView: View {
    @Environment(BrowserController.self) private var controller
    @Environment(\.colorScheme) private var colorScheme

    @State private var query = ""
    @State private var selection = 0
    @FocusState private var fieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            searchRow
            results
            footer
        }
        .frame(width: 600)
        .frame(maxHeight: 470)
        .background { panelBackground }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(borderColor, lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.5 : 0.16), radius: 32, y: 14)
        .background { keyMonitor }
        .onAppear { fieldFocused = true }
        .onChange(of: query) { _, _ in selection = 0 }
        .onChange(of: items.count) { _, count in
            selection = min(selection, max(count - 1, 0))
        }
    }

    // MARK: - Key handling

    /// Arrow keys and Esc arrive through an NSEvent monitor: SwiftUI's
    /// `onKeyPress` and plain-key `keyboardShortcut`s do not fire reliably
    /// while the palette's text field is focused on macOS.
    private var keyMonitor: some View {
        KeyMonitor { event in
            switch event.charactersIgnoringModifiers {
            case "\u{F701}": // down arrow
                moveSelection(1)
                return true
            case "\u{F700}": // up arrow
                moveSelection(-1)
                return true
            case "\u{1B}": // escape
                controller.showCommandPalette = false
                return true
            default:
                return false
            }
        }
    }

    // MARK: - Rows

    private var searchRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
            TextField("Search tabs, history, favorites, or type a command", text: $query)
                .textFieldStyle(.plain)
                .font(.body)
                .focused($fieldFocused)
                .onSubmit {
                    if let item = currentItem { perform(item) }
                }
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
    }

    @ViewBuilder
    private var results: some View {
        if items.isEmpty {
            Text("No results")
                .font(.callout)
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity)
                .frame(height: 120)
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(items.indices, id: \.self) { index in
                            row(for: items[index], index: index)
                                .id(items[index].id)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                }
                .frame(maxHeight: 380)
                .onChange(of: selection) { _, newSelection in
                    guard items.indices.contains(newSelection) else { return }
                    withAnimation(.easeOut(duration: 0.12)) {
                        proxy.scrollTo(items[newSelection].id, anchor: .center)
                    }
                }
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 14) {
            hint("↑↓", "navigate")
            hint("↩", "open")
            hint("esc", "close")
            Spacer()
        }
        .font(.system(size: 10))
        .foregroundStyle(.tertiary)
        .padding(.horizontal, 16)
        .frame(height: 30)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.primary.opacity(0.08))
                .frame(height: 0.5)
        }
    }

    private func hint(_ key: String, _ label: String) -> some View {
        HStack(spacing: 4) {
            Text(key).fontWeight(.medium)
            Text(label)
        }
    }

    // MARK: - Items

    @MainActor
    private enum PaletteItem {
        case action(PaletteAction)
        case tab(TabModel)
        case history(HistoryEntry)
        case favorite(Favorite)

        var id: String {
            switch self {
            case .action(let action): return "action-\(action.rawValue)"
            case .tab(let tab): return "tab-\(tab.id.uuidString)"
            case .history(let entry): return "history-\(entry.id)"
            case .favorite(let favorite): return "favorite-\(favorite.id.uuidString)"
            }
        }

        var url: URL? {
            switch self {
            case .history(let entry): return entry.url
            case .favorite(let favorite): return favorite.url
            case .tab(let tab): return tab.navigation.currentURL ?? tab.navigation.lastLoadedURL
            case .action: return nil
            }
        }
    }

    private var items: [PaletteItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let needle = trimmed.lowercased()

        var result: [PaletteItem] = PaletteAction.allCases
            .filter { needle.isEmpty || $0.title.lowercased().contains(needle) }
            .map { .action($0) }

        let tabs = controller.tabManager.tabs.filter { tab in
            needle.isEmpty
                || tab.displayTitle.lowercased().contains(needle)
                || (tab.address.lowercased().contains(needle))
        }
        result += tabs.map { .tab($0) }

        guard !needle.isEmpty else { return result }

        // Links: favorites first, then history, deduplicated by URL and
        // skipping URLs already listed as open tabs.
        let openURLs = Set(controller.tabManager.tabs.compactMap {
            $0.navigation.currentURL?.absoluteString ?? $0.navigation.lastLoadedURL?.absoluteString
        })
        var seen = Set<String>()
        var links: [PaletteItem] = []

        for favorite in controller.favorites.favorites {
            let key = favorite.url.absoluteString
            guard !seen.contains(key), !openURLs.contains(key) else { continue }
            let haystack = "\(favorite.title) \(favorite.url.absoluteString)".lowercased()
            guard haystack.contains(needle) else { continue }
            seen.insert(key)
            links.append(.favorite(favorite))
        }
        for entry in (controller.isPrivate ? [] : HistoryStore.shared.entries) {
            let key = entry.url.absoluteString
            guard !seen.contains(key), !openURLs.contains(key) else { continue }
            let haystack = "\(entry.title) \(entry.url.absoluteString)".lowercased()
            guard haystack.contains(needle) else { continue }
            seen.insert(key)
            links.append(.history(entry))
        }
        result += links
        return result
    }

    private var currentItem: PaletteItem? {
        items.indices.contains(selection) ? items[selection] : nil
    }

    private func moveSelection(_ delta: Int) {
        let count = items.count
        guard count > 0 else { return }
        selection = (selection + delta + count) % count
    }

    // MARK: - Row

    @ViewBuilder
    private func row(for item: PaletteItem, index: Int) -> some View {
        Button {
            perform(item)
        } label: {
            HStack(spacing: 10) {
                icon(for: item)
                    .frame(width: 18)
                Text(title(for: item))
                    .font(.callout)
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text(detail(for: item))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .frame(height: 34)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(index == selection ? Color.primary.opacity(0.08) : .clear)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            if hovering, selection != index {
                selection = index
            }
        }
    }

    @ViewBuilder
    private func icon(for item: PaletteItem) -> some View {
        switch item {
        case .action(let action):
            Image(systemName: action.symbol)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        case .tab(let tab):
            if let favicon = tab.favicon {
                Image(nsImage: favicon)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 14, height: 14)
            } else {
                Image(systemName: "globe")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        case .history:
            Image(systemName: "clock")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        case .favorite:
            Image(systemName: "star")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }

    private func title(for item: PaletteItem) -> String {
        switch item {
        case .action(let action): return action.title
        case .tab(let tab): return tab.displayTitle
        case .history(let entry): return entry.title
        case .favorite(let favorite): return favorite.title
        }
    }

    private func detail(for item: PaletteItem) -> String {
        switch item {
        case .action(let action): return action.shortcut
        case .tab(let tab): return tab.address.isEmpty ? "New Tab" : host(of: tab.address)
        case .history, .favorite:
            return host(of: item.url?.absoluteString ?? "")
        }
    }

    private func host(of urlString: String) -> String {
        guard let host = URL(string: urlString)?.host() else { return "" }
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }

    // MARK: - Actions

    private func perform(_ item: PaletteItem) {
        controller.showCommandPalette = false
        switch item {
        case .action(let action):
            action.perform(controller: controller)
        case .tab(let tab):
            controller.tabManager.select(tab)
        case .history(let entry):
            controller.open(entry.url)
        case .favorite(let favorite):
            controller.open(favorite.url)
        }
    }

    // MARK: - Chrome

    private var panelBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.regularMaterial)
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(colorScheme == .dark ? Color.black.opacity(0.55) : Color.white.opacity(0.6))
        }
    }

    private var borderColor: Color {
        Color.primary.opacity(colorScheme == .dark ? 0.14 : 0.1)
    }
}

/// Browser actions offered at the top of the palette. Titles double as the
/// search keywords, so typing "zen" or "sidebar" surfaces them directly.
@MainActor
private enum PaletteAction: String, CaseIterable {
    case newTab
    case newPrivateWindow
    case toggleSidebar
    case toggleZenMode
    case focusAddressBar
    case reloadPage

    var title: String {
        switch self {
        case .newTab: return "New Tab"
        case .newPrivateWindow: return "New Private Window"
        case .toggleSidebar: return "Toggle Sidebar"
        case .toggleZenMode: return "Toggle Zen Mode"
        case .focusAddressBar: return "Focus Address Bar"
        case .reloadPage: return "Reload This Page"
        }
    }

    var symbol: String {
        switch self {
        case .newTab: return "plus"
        case .newPrivateWindow: return "lock"
        case .toggleSidebar: return "sidebar.left"
        case .toggleZenMode: return "arrow.up.left.and.arrow.down.right"
        case .focusAddressBar: return "text.cursor"
        case .reloadPage: return "arrow.clockwise"
        }
    }

    var shortcut: String {
        switch self {
        case .newTab: return "⌘T"
        case .newPrivateWindow: return "⇧⌘N"
        case .toggleSidebar: return "⌃⌘S"
        case .toggleZenMode: return "⌘."
        case .focusAddressBar: return "⌘L"
        case .reloadPage: return "⌘R"
        }
    }

    func perform(controller: BrowserController) {
        switch self {
        case .newTab:
            controller.newTab()
        case .newPrivateWindow:
            NotificationCenter.default.post(name: .openmxcNewPrivateWindow, object: nil)
        case .toggleSidebar:
            controller.toggleSidebar()
        case .toggleZenMode:
            controller.toggleZenMode()
        case .focusAddressBar:
            NotificationCenter.default.post(name: .openmxcFocusAddressBar, object: nil)
        case .reloadPage:
            controller.selectedNavigation?.reload()
        }
    }
}
