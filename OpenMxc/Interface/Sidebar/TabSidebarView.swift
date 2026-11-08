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
                .padding(.vertical, 10)
        }
        .background(OX.background)
    }

    private var header: some View {
        HStack {
            if controller.isPrivate {
                Label("private", systemImage: "lock.fill")
                    .font(OX.mono(.callout, weight: .bold))
                    .foregroundStyle(OX.accent)
            } else {
                Text("OPENMXC")
                    .font(OX.mono(.callout, weight: .bold))
                    .tracking(0.08)
                    .foregroundStyle(OX.textPrimary)
            }
            Spacer()
            Button {
                controller.newTab()
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(.oxIcon)
            .help("New Tab (⌘T)")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var tabsList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 1) {
                if !controller.tabManager.pinnedTabs.isEmpty {
                    sectionHeader("pinned")
                    ForEach(controller.tabManager.pinnedTabs) { tab in
                        TabRowView(tab: tab)
                    }
                }

                sectionHeader("tabs")
                ForEach(controller.tabManager.unpinnedTabs) { tab in
                    TabRowView(tab: tab)
                }
            }
            .padding(.horizontal, 8)
        }
    }

    private var librarySection: some View {
        VStack(alignment: .leading, spacing: 1) {
            sectionHeader("library")

            ForEach(LibrarySection.allCases) { section in
                libraryRow(section)
            }
        }
        .padding(.horizontal, 8)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(OX.monoSmall)
            .foregroundStyle(OX.textMuted)
            .padding(.horizontal, 10)
            .padding(.top, 10)
            .padding(.bottom, 2)
    }

    private func libraryRow(_ section: LibrarySection) -> some View {
        let isSelected = controller.librarySection == section
        return Button {
            controller.showLibrary(section)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: section.symbol)
                    .font(.system(size: 11, weight: .medium))
                    .frame(width: 16)
                Text(section.title)
                    .font(OX.mono(.callout))
                Spacer()
                Text(shortcutHint(for: section))
                    .font(OX.monoSmall)
                    .foregroundStyle(OX.textMuted)
            }
            .foregroundStyle(isSelected ? OX.accent : OX.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background {
                if isSelected {
                    Rectangle()
                        .fill(OX.accent.opacity(0.10))
                }
            }
            .overlay(alignment: .leading) {
                if isSelected {
                    Rectangle().fill(OX.accent).frame(width: 2)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func shortcutHint(for section: LibrarySection) -> String {
        switch section {
        case .bookmarks: return "⌥⌘B"
        case .history: return "⌘Y"
        case .downloads: return "⌘⇧L"
        case .readingList: return ""
        }
    }
}
