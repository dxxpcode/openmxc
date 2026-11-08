import SwiftUI

struct TabSidebarView: View {
    @Environment(BrowserController.self) private var controller

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            tabsList
                .padding(.top, 8)
            Spacer()
            librarySection
                .padding(.vertical, 8)
        }
    }

    private var header: some View {
        HStack {
            if controller.isPrivate {
                Label("Private", systemImage: "hand.raised")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            } else {
                Text(BrowserConfiguration.applicationName)
                    .font(.headline)
            }
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

            ForEach(LibrarySection.allCases) { section in
                libraryRow(section)
            }
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

    private func libraryRow(_ section: LibrarySection) -> some View {
        let isSelected = controller.librarySection == section
        return Button {
            controller.showLibrary(section)
        } label: {
            Label(section.title, systemImage: section.symbol)
                .font(.callout)
                .foregroundStyle(isSelected ? Color.primary : Color.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.accentColor.opacity(0.16))
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
