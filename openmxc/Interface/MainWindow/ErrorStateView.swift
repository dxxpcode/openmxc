import SwiftUI

/// Calm full-content error state for failed or crashed pages, matching the
/// start page's restraint: one soft icon, a clear headline, one action.
struct ErrorStateView: View {
    let symbol: String
    let title: String
    let message: String
    let detail: String?
    let canGoBack: Bool
    let onRetry: () -> Void
    let onBack: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: symbol)
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(.secondary)
                .frame(width: 64, height: 64)
                .background {
                    Circle()
                        .fill(Color.primary.opacity(colorScheme == .dark ? 0.07 : 0.045))
                }
                .overlay {
                    Circle().strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
                }

            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 20, weight: .medium))
                    .tracking(-0.3)
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                if let detail, !detail.isEmpty {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 2)
                }
            }

            HStack(spacing: 10) {
                Button(action: onRetry) {
                    Text("Try Again")
                        .font(.callout.weight(.medium))
                        .padding(.horizontal, 18)
                        .frame(height: 34)
                        .background(Color.accentColor, in: Capsule())
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.defaultAction)

                if canGoBack {
                    Button(action: onBack) {
                        Text("Go Back")
                            .font(.callout.weight(.medium))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 18)
                            .frame(height: 34)
                            .background(Color.primary.opacity(0.07), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 4)
        }
        .padding(32)
        .frame(maxWidth: 420)
    }
}
