import AppKit
import Combine
import SwiftUI

/// New-tab canvas: a time-aware greeting, the search field, large top-site
/// tiles (favorites first, then frequently visited hosts), and a single quiet
/// quote that rotates daily.
struct StartPageView: View {
    @Environment(BrowserController.self) private var controller

    @State private var searchText = ""
    @State private var editingFavorite: Favorite?
    @State private var editedAddress = ""
    @FocusState private var isSearchFocused: Bool
    @State private var now = Date()

    private static let quotes: [(text: String, author: String)] = [
        ("Simplicity is the ultimate sophistication.", "Leonardo da Vinci"),
        ("The best way to predict the future is to invent it.", "Alan Kay"),
        ("Stay hungry, stay foolish.", "Steve Jobs"),
        ("It does not matter how slowly you go as long as you do not stop.", "Confucius"),
        ("Everything should be made as simple as possible, but not simpler.", "Albert Einstein"),
        ("The only way to do great work is to love what you do.", "Steve Jobs"),
        ("In the middle of difficulty lies opportunity.", "Albert Einstein"),
        ("What we think, we become.", "Buddha"),
        ("Perfection is achieved, not when there is nothing more to add, but when there is nothing left to take away.", "Antoine de Saint-Exupéry"),
        ("Make it work, make it right, make it fast.", "Kent Beck"),
        ("The web is more a social creation than a technical one.", "Tim Berners-Lee"),
        ("Done is better than perfect.", "Sheryl Sandberg"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 30) {
                dateTimeView

                Image("OpenMxcLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 34, height: 34)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Text(greeting)
                    .font(.system(size: 30, weight: .medium))
                    .tracking(-0.4)

                searchField

                topSitesRow
            }

            Spacer()

            quoteView
                .padding(.bottom, 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
        .onReceive(Self.clockTimer(after: now)) { date in
            now = date
        }
        .alert("Edit Address", isPresented: Binding(
            get: { editingFavorite != nil },
            set: { if !$0 { editingFavorite = nil } }
        )) {
            TextField("Address", text: $editedAddress)
            Button("Cancel", role: .cancel) { editingFavorite = nil }
            Button("Save") { saveEditedAddress() }
        }
    }

    /// Fires just after each minute boundary so the displayed minute never lags.
    private static func clockTimer(after date: Date) -> Publishers.Autoconnect<Timer.TimerPublisher> {
        let calendar = Calendar.current
        let seconds = Double(calendar.component(.second, from: date))
        let nanos = Double(calendar.component(.nanosecond, from: date))
        let interval = max(1, 60 - seconds - nanos / 1_000_000_000)
        return Timer.publish(every: interval, on: .main, in: .common).autoconnect()
    }

    private var dateTimeView: some View {
        VStack(spacing: 7) {
            Text(now, style: .time)
                .font(.system(size: 44, weight: .medium))
                .tracking(-1.2)
                .monospacedDigit()
                .contentTransition(.numericText())
            Text(now.formatted(Date.FormatStyle(date: .complete, time: .omitted).month(.wide).day().year().locale(Locale.current)))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
                .tracking(0.2)
        }
        .animation(Motion.quick, value: now)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    private var searchField: some View {
        SearchField(
            placeholder: "Search or enter address",
            text: $searchText,
            height: 44,
            focus: $isSearchFocused
        ) {
            controller.navigate(to: searchText)
            searchText = ""
        }
        .frame(width: 560)
    }

    // MARK: - Top sites

    private var topSites: [TopSite] {
        var sites: [TopSite] = []
        var seenHosts = Set<String>()

        for favorite in controller.favorites.favorites {
            guard let host = favorite.url.host(), !seenHosts.contains(host) else { continue }
            seenHosts.insert(host)
            sites.append(TopSite(title: favorite.title, url: favorite.url, favorite: favorite))
        }

        var visitCounts: [String: (count: Int, title: String, url: URL)] = [:]
        let historyEntries = controller.isPrivate ? [] : HistoryStore.shared.entries
        for entry in historyEntries {
            guard let host = entry.url.host(), !seenHosts.contains(host) else { continue }
            if var existing = visitCounts[host] {
                existing.count += 1
                visitCounts[host] = existing
            } else {
                visitCounts[host] = (1, entry.title, entry.url)
            }
        }

        let byFrequency = visitCounts
            .sorted { $0.value.count > $1.value.count }
            .prefix(8 - sites.count)
        for (host, value) in byFrequency {
            seenHosts.insert(host)
            let displayHost = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
            sites.append(TopSite(title: displayHost, url: value.url, favorite: nil))
        }

        return Array(sites.prefix(8))
    }

    @ViewBuilder
    private var topSitesRow: some View {
        let sites = topSites
        if !sites.isEmpty {
            HStack(spacing: 30) {
                ForEach(sites) { site in
                    TopSiteTileView(site: site) {
                        controller.navigate(to: site.url.absoluteString)
                    } contextMenu: {
                        if let favorite = site.favorite {
                            Button("Edit Address…") {
                                editedAddress = favorite.url.absoluteString
                                editingFavorite = favorite
                            }
                            Divider()
                            Button("Remove Favorite", role: .destructive) {
                                controller.favorites.remove(favorite)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: 720)
        }
    }

    // MARK: - Quote

    private var quoteView: some View {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        let quote = Self.quotes[day % Self.quotes.count]
        return VStack(spacing: 6) {
            Text("“\(quote.text)”")
                .font(.callout)
                .foregroundStyle(.secondary)
            Text("— \(quote.author)")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 48)
    }

    private func saveEditedAddress() {
        guard let favorite = editingFavorite,
              let url = SearchService.resolve(editedAddress)
        else {
            editingFavorite = nil
            return
        }
        controller.favorites.updateAddress(favorite, url: url)
        editingFavorite = nil
    }
}

private struct TopSite: Identifiable {
    let title: String
    let url: URL
    let favorite: Favorite?

    var id: String { url.absoluteString }
}

private struct TopSiteTileView<MenuContent: View>: View {
    let site: TopSite
    let action: () -> Void
    @ViewBuilder let contextMenu: () -> MenuContent

    @Environment(\.colorScheme) private var colorScheme
    @State private var icon: NSImage?
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                iconView
                Text(site.title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(width: 84)
            }
        }
        .buttonStyle(.plain)
        .offset(y: isHovered ? -3 : 0)
        .animation(Motion.quick, value: isHovered)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
        .contextMenu { contextMenu() }
        .onAppear {
            FaviconService.shared.icon(for: site.url) { image in
                icon = image
            }
        }
        .help(site.url.host() ?? site.title)
        .accessibilityLabel("Open \(site.title)")
    }

    @ViewBuilder
    private var iconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.primary.opacity(fillOpacity))
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(borderColor, lineWidth: 0.5)
            if let icon {
                if colorScheme == .dark {
                    // Dark favicons vanish on the dark tile; give them a light
                    // backing plate, like Safari's dark-mode top sites.
                    Image(nsImage: icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 26, height: 26)
                        .padding(7)
                        .background(
                            Color.white,
                            in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                        )
                } else {
                    Image(nsImage: icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                }
            } else {
                Image(systemName: "globe")
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(width: 56, height: 56)
        .shadow(
            color: .black.opacity(isHovered ? (colorScheme == .dark ? 0.4 : 0.1) : 0),
            radius: isHovered ? 10 : 0,
            y: isHovered ? 4 : 0
        )
        .animation(Motion.quick, value: isHovered)
    }

    private var fillOpacity: Double {
        if colorScheme == .dark {
            return isHovered ? 0.1 : 0.07
        }
        return isHovered ? 0.05 : 0.03
    }

    private var borderColor: Color {
        if isHovered {
            return Color.primary.opacity(colorScheme == .dark ? 0.35 : 0.28)
        }
        return Color.primary.opacity(colorScheme == .dark ? 0.16 : 0.09)
    }
}
