import SwiftUI

struct TabSidebarView: View {
    @Environment(BrowserController.self) private var controller

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            tabsList
                .padding(.top, 8)
            Spacer()
            Divider()
            librarySection
                .padding(.vertical, 8)
        }
        .background(.regularMaterial)
    }

    private var header: some View {
        HStack {
            Text(BrowserConfiguration.applicationName)
                .font(.headline)
            Spacer()
            Button {
                controller.newTab()
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(.borderless)
            .help("New Tab")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var tabsList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 2) {
                if !controller.tabManager.pinnedTabs.isEmpty {
                    sectionHeader("Pinned")
                    ForEach(controller.tabManager.pinnedTabs) { tab in
                        TabRowView(tab: tab)
                    }
                }

                sectionHeader("Tabs")
                ForEach(controller.tabManager.unpinnedTabs) { tab in
                    TabRowView(tab: tab)
                }
            }
            .padding(.horizontal, 8)
        }
    }

    private var librarySection: some View {
        VStack(alignment: .leading, spacing: 2) {
            sectionHeader("Library")

            libraryRow("bookmark", "Bookmarks")
            libraryRow("text.bookmark", "Reading List")
            libraryRow("clock", "History")
            libraryRow("arrow.down.circle", "Downloads")
        }
        .padding(.horizontal, 8)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 4)
    }

    private func libraryRow(_ symbol: String, _ title: String) -> some View {
        Label(title, systemImage: symbol)
            .font(.callout)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .disabled(true)
    }
}
