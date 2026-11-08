import SwiftUI

struct ReadingListLibraryView: View {
    @Environment(BrowserController.self) private var controller

    @State private var searchText = ""

    private var store: ReadingListStore { .shared }

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
                TextField("Search reading list", text: $searchText)
                .textFieldStyle(.plain)
            }
            .padding(.horizontal, 10)
            .frame(maxWidth: 280, minHeight: 30)
            .glassField(cornerRadius: 9)

            Spacer()

            Button {
                addCurrentPage()
            } label: {
                Label("Add This Page", systemImage: "plus")
            }
            .disabled(controller.selectedNavigation?.currentURL == nil)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var listContent: some View {
        let items = store.search(searchText)
        if items.isEmpty {
            ContentUnavailableView(
                "Reading List",
                systemImage: "text.bookmark",
                description: Text(searchText.isEmpty
                    ? "Save pages to read later."
                    : "No items match your search.")
            )
        } else {
            List(items) { item in
                Button {
                    controller.navigate(to: item.url.absoluteString)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: item.isRead ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(item.isRead ? Color.accentColor : Color.secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .lineLimit(1)
                                .strikethrough(item.isRead)
                            Text(item.url.host() ?? item.url.absoluteString)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button("Open") {
                        controller.navigate(to: item.url.absoluteString)
                    }
                    Button(item.isRead ? "Mark as Unread" : "Mark as Read") {
                        store.setRead(item, isRead: !item.isRead)
                    }
                    Divider()
                    Button("Remove", role: .destructive) {
                        store.remove(item)
                    }
                }
            }
        }
    }

    private func addCurrentPage() {
        guard let tab = controller.tabManager.selectedTab,
              let url = tab.navigation.currentURL ?? tab.navigation.lastLoadedURL
        else { return }
        store.add(title: tab.displayTitle, url: url)
    }
}
