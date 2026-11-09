import SwiftUI

/// One row in the address bar's suggestion dropdown: a favorite/history match
/// or the "Search for …" fallback.
struct AddressSuggestionRow: Identifiable, Hashable {
    enum Kind: Hashable {
        case favorite
        case history
        case search
    }

    let id: String
    let kind: Kind
    let title: String
    let detail: String
    let url: URL?
}

/// Quiet dropdown shown beneath the address field while typing. Purely
/// presentational — the toolbar owns the data, selection, and keyboard nav.
struct AddressSuggestionsView: View {
    let rows: [AddressSuggestionRow]
    let selectedIndex: Int
    let onHover: (Int) -> Void
    let onSelect: (AddressSuggestionRow) -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 1) {
            ForEach(rows.indices, id: \.self) { index in
                rowView(rows[index], index: index)
            }
        }
        .padding(4)
        .background { panelBackground }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(borderColor, lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.4 : 0.12), radius: 16, y: 6)
    }

    @ViewBuilder
    private func rowView(_ row: AddressSuggestionRow, index: Int) -> some View {
        Button {
            onSelect(row)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: symbol(for: row.kind))
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 16)
                Text(row.title)
                    .font(.callout)
                    .lineLimit(1)
                Spacer(minLength: 8)
                if !row.detail.isEmpty {
                    Text(row.detail)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 10)
            .frame(height: 34)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(index == selectedIndex ? Color.primary.opacity(0.08) : .clear)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            if hovering { onHover(index) }
        }
    }

    private func symbol(for kind: AddressSuggestionRow.Kind) -> String {
        switch kind {
        case .favorite: return "star"
        case .history: return "clock"
        case .search: return "magnifyingglass"
        }
    }

    private var panelBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.regularMaterial)
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(colorScheme == .dark ? Color.black.opacity(0.55) : Color.white.opacity(0.65))
        }
    }

    private var borderColor: Color {
        Color.primary.opacity(colorScheme == .dark ? 0.14 : 0.1)
    }
}
