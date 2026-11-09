import Foundation

/// A classified navigation failure so the UI can show a calm, specific state
/// instead of a raw error string.
struct LoadFailure: Equatable {
    enum Kind: Equatable {
        case offline
        case timedOut
        case unreachable
        case generic
    }

    let kind: Kind
    let detail: String

    init(nsError: NSError) {
        detail = nsError.localizedDescription
        guard nsError.domain == NSURLErrorDomain else {
            kind = .generic
            return
        }
        switch nsError.code {
        case NSURLErrorNotConnectedToInternet:
            kind = .offline
        case NSURLErrorTimedOut:
            kind = .timedOut
        case NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost, NSURLErrorNetworkConnectionLost:
            kind = .unreachable
        default:
            kind = .generic
        }
    }
}
