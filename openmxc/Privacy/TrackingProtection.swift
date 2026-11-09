import Foundation
import WebKit

/// Compiles and applies a basic content-blocking rule list through WebKit's
/// supported WKContentRuleListStore API. This is a modest tracker blocklist,
/// not a promise of complete tracking prevention.
@Observable
@MainActor
final class TrackingProtection {
    static let shared = TrackingProtection(database: .shared)

    static let enabledKey = "trackingProtectionEnabled"

    private let database: Database
    private(set) var ruleList: WKContentRuleList?
    private var compileTask: Task<Void, Never>?

    init(database: Database) {
        self.database = database
    }

    var isEnabled: Bool {
        AppSettings.bool(Self.enabledKey, default: true, database: database)
    }

    func setEnabled(_ enabled: Bool) {
        AppSettings.setBool(Self.enabledKey, enabled, database: database)
        if enabled {
            compileIfNeeded()
        } else {
            ruleList = nil
        }
    }

    /// Call once at launch, before windows are created.
    func prepare() {
        guard isEnabled else { return }
        compileIfNeeded()
    }

    private func compileIfNeeded() {
        guard ruleList == nil, compileTask == nil else { return }
        compileTask = Task { @MainActor [weak self] in
            guard let store = WKContentRuleListStore.default() else {
                self?.compileTask = nil
                return
            }
            do {
                let list = try await store.compileContentRuleList(
                    forIdentifier: "openmxc-tracking-protection",
                    encodedContentRuleList: Self.rulesJSON
                )
                self?.ruleList = list
            } catch {
                // Content blocking is best-effort; browsing continues without it.
            }
            self?.compileTask = nil
        }
    }

    /// Applies the compiled rule list to an already-created web view.
    /// Used for web views created before compilation finished.
    func apply(to webView: WKWebView) {
        guard isEnabled, let ruleList else { return }
        webView.configuration.userContentController.add(ruleList)
    }

    private static let rulesJSON = """
        [
          {
            "trigger": { "url-filter": "doubleclick\\\\.net", "resource-type": ["script", "image", "xmlhttprequest"] },
            "action": { "type": "block" }
          },
          {
            "trigger": { "url-filter": "googlesyndication\\\\.com", "resource-type": ["script", "image", "xmlhttprequest"] },
            "action": { "type": "block" }
          },
          {
            "trigger": { "url-filter": "google-analytics\\\\.com", "resource-type": ["script", "xmlhttprequest"] },
            "action": { "type": "block" }
          },
          {
            "trigger": { "url-filter": "googletagmanager\\\\.com", "resource-type": ["script"] },
            "action": { "type": "block" }
          },
          {
            "trigger": { "url-filter": "facebook\\\\.net/tr", "resource-type": ["script", "xmlhttprequest"] },
            "action": { "type": "block" }
          },
          {
            "trigger": { "url-filter": "connect\\\\.facebook\\\\.net", "resource-type": ["xmlhttprequest"] },
            "action": { "type": "block" }
          }
        ]
        """
}
