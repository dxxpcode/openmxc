import SwiftUI
import WebKit

/// Bottom-dock tab switcher and library. Opened with ⌘⇧A (tabs) or ⌘⌥L (library).
struct TabDockView: View {
    @Environment(BrowserController.self) private var controller

    @State private var query = ""
    @State private var highlightedID: UUID?
    @State private var isPresented = false
    @State private var snapshots: [UUID: NSImage] = [:]
    @FocusState private var searchFocused: Bool

    private var tabs: [TabModel] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return controller.tabManager.tabs }
        return controller.tabManager.tabs.filter {
            $0.displayTitle.localizedCaseInsensitiveContains(trimmed)
                || $0.address.localizedCaseInsensitiveContains(trimmed)
        }
    }

    private var isTabsMode: Bool {
        if case .tabs = controller.tabDockMode { return true }
        return false
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(isPresented ? 0.16 : 0)
                .ignoresSafeArea()
                .onTapGesture(perform: close)

            dock
                .padding(.horizontal, 28)
                .padding(.bottom, 16)
                .offset(y: isPresented ? 0 : 36)
                .opacity(isPresented ? 1 : 0)
        }
        .onAppear {
            highlightedID = controller.tabManager.selectedTabID ?? tabs.first?.id
            searchFocused = true
            captureSnapshots()
            withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                isPresented = true
            }
        }
    }

    private var dock: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                searchField
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity)

            iconColumn
        }
        .frame(height: isTabsMode ? 318 : 436)
        .animation(.spring(response: 0.3, dampingFraction: 0.9), value: controller.tabDockMode)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.2), radius: 32, y: 16)
    }

    // MARK: - Search

    private var searchField: some View {
        HStack(spacing: 9) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.tertiary)
            TextField(isTabsMode ? "Search tabs" : "Search \(librarySection.title.lowercased())", text: $query)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .focused($searchFocused)
                .onSubmit {
                    if isTabsMode { openHighlighted() }
                }
                .onKeyPress(.upArrow) {
                    guard isTabsMode else { return .ignored }
                    moveHighlight(by: -1)
                    return .handled
                }
                .onKeyPress(.downArrow) {
                    guard isTabsMode else { return .ignored }
                    moveHighlight(by: 1)
                    return .handled
                }
                .onKeyPress(.escape) {
                    close()
                    return .handled
                }
                .onChange(of: query) { _, _ in
                    highlightedID = isTabsMode ? tabs.first?.id : nil
                }
        }
        .padding(.horizontal, 16)
        .frame(height: 50)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if isTabsMode {
            tabsCarousel
        } else {
            DockLibraryView(section: librarySection, query: query) { url in
                controller.open(url: url)
                close()
            }
        }
    }

    private var tabsCarousel: some View {
        Group {
            if tabs.isEmpty {
                Text("No matching tabs")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 14) {
                            ForEach(tabs) { tab in
                                TabPreviewCard(
                                    tab: tab,
                                    snapshot: snapshots[tab.id],
                                    isHighlighted: tab.id == highlightedID,
                                    isCurrent: tab.id == controller.tabManager.selectedTabID,
                                    onHover: { highlightedID = tab.id },
                                    onSelect: {
                                        highlightedID = tab.id
                                        openHighlighted()
                                    },
                                    onClose: { closeTab(tab) }
                                )
                                .id(tab.id)
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 6)
                    }
                    .onChange(of: highlightedID) { _, id in
                        guard let id else { return }
                        withAnimation(.easeInOut(duration: 0.15)) {
                            proxy.scrollTo(id, anchor: .center)
                        }
                    }
                }
            }
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.primary.opacity(0.08))
                .frame(height: 0.5)
                .padding(.horizontal, 18)
        }
    }

    // MARK: - Icon column

    private var iconColumn: some View {
        VStack(spacing: 3) {
            dockIcon("rectangle.stack", title: "Tabs", mode: .tabs)

            Rectangle()
                .fill(Color.primary.opacity(0.1))
                .frame(width: 24, height: 0.5)
                .padding(.vertical, 7)

            ForEach(LibrarySection.allCases) { section in
                dockIcon(section.symbol, title: section.title, mode: .library(section))
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 14)
        .frame(width: 60)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(Color.primary.opacity(0.08))
                .frame(width: 0.5)
        }
    }

    private func dockIcon(_ symbol: String, title: String, mode: TabDockMode) -> some View {
        let isSelected = controller.tabDockMode == mode
        return Button {
            controller.toggleTabDock(mode)
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                .frame(width: 38, height: 34)
                .background {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(isSelected ? Color.accentColor.opacity(0.14) : .clear)
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(title)
        .accessibilityLabel(title)
    }

    // MARK: - Actions

    private func moveHighlight(by offset: Int) {
        guard !tabs.isEmpty else { return }
        let currentIndex = tabs.firstIndex { $0.id == highlightedID } ?? 0
        let next = (currentIndex + offset + tabs.count) % tabs.count
        highlightedID = tabs[next].id
    }

    private func openHighlighted() {
        guard let tab = tabs.first(where: { $0.id == highlightedID }) ?? tabs.first else { return }
        controller.tabManager.select(tab)
        close()
    }

    private func closeTab(_ tab: TabModel) {
        let wasHighlighted = tab.id == highlightedID
        controller.tabManager.closeTab(tab)
        if wasHighlighted {
            highlightedID = tabs.first?.id
        }
    }

    private func close() {
        withAnimation(.easeOut(duration: 0.12)) {
            isPresented = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            controller.showTabDock = false
        }
    }

    // MARK: - Snapshots

    /// Captures lightweight thumbnails of loaded tabs for the preview cards.
    /// Tabs that have never been displayed fall back to a typographic placeholder.
    private func captureSnapshots() {
        for tab in controller.tabManager.tabs.prefix(12) {
            guard let url = tab.navigation.webView.url,
                  url.scheme == "http" || url.scheme == "https"
            else { continue }
            captureSnapshot(for: tab)
        }
    }

    private func captureSnapshot(for tab: TabModel) {
        let webView = tab.navigation.webView
        let isOnScreen = webView.window != nil
        let originalFrame = webView.frame

        if !isOnScreen {
            webView.frame = CGRect(x: -20_000, y: -20_000, width: 960, height: 600)
        }

        let bounds = webView.bounds
        guard bounds.width > 1, bounds.height > 1 else {
            if !isOnScreen { webView.frame = originalFrame }
            return
        }

        let configuration = WKSnapshotConfiguration()
        configuration.rect = CGRect(origin: .zero, size: bounds.size)
        configuration.snapshotWidth = 416

        webView.takeSnapshot(with: configuration) { image, _ in
            if !isOnScreen {
                webView.frame = originalFrame
            }
            guard let image else { return }
            Task { @MainActor in
                snapshots[tab.id] = image
            }
        }
    }

    private var librarySection: LibrarySection {
        if case .library(let section) = controller.tabDockMode { return section }
        return .history
    }
}

// MARK: - Tab preview card

private struct TabPreviewCard: View {
    let tab: TabModel
    let snapshot: NSImage?
    let isHighlighted: Bool
    let isCurrent: Bool
    let onHover: () -> Void
    let onSelect: () -> Void
    let onClose: () -> Void

    @State private var isHovered = false

    private let cardWidth: CGFloat = 204
    private let thumbnailHeight: CGFloat = 116

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            thumbnail
                .frame(width: cardWidth, height: thumbnailHeight)
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .strokeBorder(
                            isHighlighted ? Color.accentColor : Color.primary.opacity(0.1),
                            lineWidth: isHighlighted ? 2 : 0.5
                        )
                }
                .shadow(color: .black.opacity(isHighlighted ? 0.16 : 0.06), radius: isHighlighted ? 10 : 4, y: 3)

            HStack(spacing: 7) {
                FaviconTile(image: tab.favicon, size: 16)
                VStack(alignment: .leading, spacing: 1) {
                    Text(tab.displayTitle)
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                    Text(tab.navigation.currentURL?.host() ?? "New Tab")
                        .font(.system(size: 10.5))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 4)
                if isCurrent {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 5, height: 5)
                        .accessibilityLabel("Current tab")
                }
            }
            .padding(.horizontal, 2)
        }
        .frame(width: cardWidth)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
            if hovering { onHover() }
        }
        .onTapGesture(perform: onSelect)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }

    @ViewBuilder
    private var thumbnail: some View {
        ZStack {
            LinearGradient(
                colors: [Color.primary.opacity(0.09), Color.primary.opacity(0.03)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            if let snapshot {
                Image(nsImage: snapshot)
                    .resizable()
                    .scaledToFill()
            } else {
                VStack(spacing: 8) {
                    FaviconTile(image: tab.favicon, size: 34)
                    Text(tab.displayTitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .padding(.horizontal, 16)
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            if isHovered && !tab.isPinned {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 18, height: 18)
                        .background(.regularMaterial, in: Circle())
                        .overlay { Circle().strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5) }
                }
                .buttonStyle(.plain)
                .padding(5)
                .help("Close Tab")
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.12), value: isHovered)
    }
}

// MARK: - Shared favicon tile

struct FaviconTile: View {
    let image: NSImage?
    var size: CGFloat = 24

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
                .fill(Color.primary.opacity(0.05))
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.62, height: size * 0.62)
            } else {
                Image(systemName: "globe")
                    .font(.system(size: size * 0.45))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(width: size, height: size)
    }
}
