import SwiftUI

struct TabSidebarView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            tabsSection
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
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var tabsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionHeader("Tabs")

            HStack(spacing: 8) {
                Image(systemName: "globe")
                    .foregroundStyle(.tertiary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("No open tabs")
                        .font(.callout)
                    Text("Tabs you open will appear here.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
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
