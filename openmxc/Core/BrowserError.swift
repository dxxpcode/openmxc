import Foundation

enum BrowserError: LocalizedError {
    case invalidAddress(String)

    var errorDescription: String? {
        switch self {
        case .invalidAddress(let input):
            return "“\(input)” is not a valid address."
        }
    }
}
