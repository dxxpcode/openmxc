import SwiftUI

struct LibraryView: View {
    @Environment(BrowserController.self) private var controller
    let section: LibrarySection

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        HStack {
            Label(section.title, systemImage: section.symbol)
                .font(.headline)
            Spacer()
            Button {
                controller.librarySection = nil
            } label: {
                Image(systemName: "xmark")
            }
            .buttonStyle(.chromeIcon)
            .help("Back to Tabs")
            .accessibilityLabel("Back to Tabs")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var content: some View {
        switch section {
        case .bookmarks:
            BookmarksLibraryView()
        case .readingList:
            ReadingListLibraryView()
        case .history:
            HistoryLibraryView()
        case .downloads:
            DownloadsLibraryView()
        }
    }
}
