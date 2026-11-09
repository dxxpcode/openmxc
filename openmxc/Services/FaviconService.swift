import AppKit
import Foundation

@MainActor
final class FaviconService {
    static let shared = FaviconService()

    private var cache: [String: NSImage] = [:]
    private var inFlight: Set<String> = []

    private init() {}

    func icon(for url: URL, completion: @escaping (NSImage?) -> Void) {
        guard let scheme = url.scheme, let host = url.host, !host.isEmpty else {
            completion(nil)
            return
        }
        guard scheme == "http" || scheme == "https" else {
            completion(nil)
            return
        }

        let key = "\(scheme)://\(host)/favicon.ico"
        if let cached = cache[key] {
            completion(cached)
            return
        }
        guard !inFlight.contains(key), let iconURL = URL(string: key) else {
            completion(nil)
            return
        }

        inFlight.insert(key)
        Task {
            let image = await Self.fetchIcon(from: iconURL)
            inFlight.remove(key)
            if let image {
                cache[key] = image
            }
            await MainActor.run {
                completion(image)
            }
        }
    }

    private static func fetchIcon(from url: URL) async -> NSImage? {
        guard let (data, response) = try? await URLSession.shared.data(from: url),
              let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode),
              let image = NSImage(data: data)
        else { return nil }
        return image
    }
}
