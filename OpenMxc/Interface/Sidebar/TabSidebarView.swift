import SwiftUI

struct TabSidebarView: View {
    @Environment(BrowserController.self) private var controller

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            tabsList
                .padding(.top, 6)
            Spacer()
            librarySection
                .padding(.vertical, 10)
        }
        .background(.thinMaterial)
    }

    private var header: some View {
        HStack(spacing: 8) {
            if controller.isPrivate {
                Label("Private", systemImage: "lock.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
            } else {
                Text(BrowserConfiguration.applicationName)
                    .font(.system(size: 13, weight: .bold))
                    .tracking(0.5)
            }
            Spacer()
            Button {
                controller.newTab()
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(.glassIcon)
            .help("New Tab")
            .accessibilityLabel("New Tab")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
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
            .padding(.horizontal, 10)
        }
    }

    private var librarySection: some View {
        VStack(alignment: .leading, spacing: 2) {
            sectionHeader("Library")

            ForEach(LibrarySection.allCases) { section in
                libraryRow(section)
            }
        }
        .padding(.horizontal, 10)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.tertiary)
            .padding(.horizontal, 10)
            .padding(.top, 10)
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
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(Color.accentColor.opacity(0.18))
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
