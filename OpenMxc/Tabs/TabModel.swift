import AppKit
import Foundation

@Observable
@MainActor
final class TabModel: Identifiable {
    let id = UUID()
    let navigation: NavigationManager

    var isPinned = false
    var isMuted = false
    var customTitle: String?
    var favicon: NSImage?

    init(url: URL? = nil) {
        navigation = NavigationManager()
        if let url {
            navigation.load(url)
        }
        observeURLForFavicon()
    }

    var displayTitle: String {
        if let customTitle, !customTitle.isEmpty { return customTitle }
        if !navigation.pageTitle.isEmpty { return navigation.pageTitle }
        if let host = navigation.currentURL?.host() { return host }
        return "New Tab"
    }

    var address: String {
        navigation.currentURL?.absoluteString ?? ""
    }

    var isLoading: Bool { navigation.isLoading }

    func setMuted(_ muted: Bool) {
        guard muted != isMuted else { return }
        isMuted = muted
        let script = muted ? TabModel.muteScript : TabModel.unmuteScript
        navigation.webView.evaluateJavaScript(script, completionHandler: nil)
    }

    func reload() {
        navigation.reload()
    }

    private func observeURLForFavicon() {
        withObservationTracking {
            _ = navigation.currentURL
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.updateFavicon()
                self.observeURLForFavicon()
            }
        }
    }

    private func updateFavicon() {
        guard let url = navigation.currentURL else {
            favicon = nil
            return
        }
        FaviconService.shared.icon(for: url) { [weak self] image in
            self?.favicon = image
        }
    }

    private static let muteScript = """
        (function() {
            window.__openmxcMuteObserver = window.__openmxcMuteObserver || null;
            function muteMedia(root) {
                root.querySelectorAll('video, audio').forEach(function(media) {
                    media.muted = true;
                    media.volume = 0;
                });
            }
            muteMedia(document);
            if (!window.__openmxcMuteObserver) {
                window.__openmxcMuteObserver = new MutationObserver(function(mutations) {
                    mutations.forEach(function(mutation) {
                        mutation.addedNodes.forEach(function(node) {
                            if (node.nodeType === 1) muteMedia(node);
                        });
                    });
                });
                window.__openmxcMuteObserver.observe(document.documentElement, { childList: true, subtree: true });
            }
        })();
        """

    private static let unmuteScript = """
        (function() {
            if (window.__openmxcMuteObserver) {
                window.__openmxcMuteObserver.disconnect();
                window.__openmxcMuteObserver = null;
            }
            document.querySelectorAll('video, audio').forEach(function(media) {
                media.muted = false;
                media.volume = 1;
            });
        })();
        """
}
