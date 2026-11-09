import SwiftUI

/// The app's single motion language: one spring curve at two durations.
///
/// `standard` drives panel/overlay entrances, content swaps, and structural
/// changes; `quick` drives hover, press, and focus feedback. Both share the
/// same response and bounce, so every animation in the app reads as the same
/// physical object.
enum Motion {
    static let standard = Animation.spring(duration: 0.28, bounce: 0.12)
    static let quick = Animation.spring(duration: 0.18, bounce: 0.12)
}
