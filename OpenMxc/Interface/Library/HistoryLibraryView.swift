import AppKit
import SwiftUI

struct HistoryLibraryView: View {
    @Environment(BrowserController.self) private var controller

    @State private var searchText = ""

    private var store: HistoryStore { .shared }

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            listContent
        }
    }

    private var toolbar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search history", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(.horizontal, 10)
            .frame(maxWidth: 280, minHeight: 30)
            .chromeField()

            Spacer()

            Menu("Clear History") {
                Button("Last Hour") { clear(olderThan: Date().addingTimeInterval(-3600)) }
                Button("Today") {
                    clear(olderThan: Calendar.current.startOfDay(for: Date()))
                }
                Button("Last 7 Days") { clear(olderThan: Date().addingTimeInterval(-7 * 24 * 3600)) }
                Divider()
                Button("All History", role: .destructive) {
                    store.clearAll()
                }
            }
            .buttonStyle(.borderless)

            Menu("Website Data") {
                Button("Clear Cookies and Website Data…") {
                    clearWebsiteData()
                }
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var listContent: some View {
        let entries = store.search(searchText)
        if entries.isEmpty {
            ContentUnavailableView(
                "History",
                systemImage: "clock",
                description: Text(searchText.isEmpty
                    ? "Pages you visit will appear here."
                    : "No entries match your search.")
            )
        } else {
            List {
                ForEach(groupedEntries(entries), id: \.title) { group in
                    Section(group.title) {
                        ForEach(group.entries) { entry in
                            historyRow(entry)
                        }
                    }
                }
            }
        }
    }

    private struct DayGroup {
        let title: String
        let entries: [HistoryEntry]
    }

    private func groupedEntries(_ entries: [HistoryEntry]) -> [DayGroup] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var groups: [(title: String, entries: [HistoryEntry])] = []
        var indexByTitle: [String: Int] = [:]

        for entry in entries {
            let day = calendar.startOfDay(for: entry.visitedAt)
            let title: String
            if day == today {
                title = "Today"
            } else if day == calendar.date(byAdding: .day, value: -1, to: today) {
                title = "Yesterday"
            } else {
                title = entry.visitedAt.formatted(.dateTime.weekday(.wide).month(.wide).day().year())
            }
            if let index = indexByTitle[title] {
                groups[index].entries.append(entry)
            } else {
                indexByTitle[title] = groups.count
                groups.append((title: title, entries: [entry]))
            }
        }
        return groups.map { DayGroup(title: $0.title, entries: $0.entries) }
    }

    private func historyRow(_ entry: HistoryEntry) -> some View {
        Button {
            controller.navigate(to: entry.url.absoluteString)
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(entry.url.host() ?? entry.url.absoluteString)
                        .lineLimit(1)
                    Text(entry.visitedAt, style: .relative)
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Open") {
                controller.navigate(to: entry.url.absoluteString)
            }
            Divider()
            Button("Delete", role: .destructive) {
                store.delete(entry)
            }
        }
    }

    private func clear(olderThan date: Date) {
        store.clear(.olderThan(date))
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
