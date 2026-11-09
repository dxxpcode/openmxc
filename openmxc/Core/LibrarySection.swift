import Foundation

enum LibrarySection: String, CaseIterable, Identifiable {
    case bookmarks
    case readingList
    case history
    case downloads

    var id: String { rawValue }

    var title: String {
        switch self {
        case .bookmarks: return "Bookmarks"
        case .readingList: return "Reading List"
        case .history: return "History"
        case .downloads: return "Downloads"
        }
    }

    var symbol: String {
        switch self {
        case .bookmarks: return "bookmark"
        case .readingList: return "text.bookmark"
        case .history: return "clock"
        case .downloads: return "arrow.down.circle"
        }
    }
}
