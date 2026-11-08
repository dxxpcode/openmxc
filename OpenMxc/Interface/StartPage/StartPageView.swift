import AppKit
import SwiftUI

struct StartPageView: View {
    @Environment(BrowserController.self) private var controller
    @Environment(\.colorScheme) private var colorScheme

    @State private var searchText = ""
    @State private var editingFavorite: Favorite?
    @State private var editedAddress = ""
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 24) {
                Image("OpenMxcLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))

                searchField

                favoritesRow
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
        .alert("Edit Address", isPresented: Binding(
            get: { editingFavorite != nil },
            set: { if !$0 { editingFavorite = nil } }
        )) {
            TextField("Address", text: $editedAddress)
            Button("Cancel", role: .cancel) { editingFavorite = nil }
            Button("Save") { saveEditedAddress() }
        }
    }

    private var searchField: some View {
        SearchField(
            placeholder: "Search or enter address",
            text: $searchText,
            height: 40,
            focus: $isSearchFocused
        ) {
            controller.navigate(to: searchText)
            searchText = ""
        }
        .frame(width: 520)
    }

    @ViewBuilder
    private var favoritesRow: some View {
        if !controller.favorites.favorites.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 24) {
                    ForEach(controller.favorites.favorites) { favorite in
                        FavoriteTileView(favorite: favorite) {
                            controller.openFavorite(favorite)
                        }
                        .contextMenu {
                            Button("Open") {
                                controller.openFavorite(favorite)
                            }
                            Button("Edit Address…") {
                                editedAddress = favorite.url.absoluteString
                                editingFavorite = favorite
                            }
                            Divider()
                            Button("Remove Favorite", role: .destructive) {
                                controller.favorites.remove(favorite)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            .frame(maxWidth: 640)
        }
    }

    private func saveEditedAddress() {
        guard let favorite = editingFavorite,
              let url = SearchService.resolve(editedAddress)
        else {
            editingFavorite = nil
            return
        }
        controller.favorites.updateAddress(favorite, url: url)
        editingFavorite = nil
    }
}

private struct FavoriteTileView: View {
    let favorite: Favorite
    let action: () -> Void

    @State private var icon: NSImage?
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                iconView
                Text(favorite.title)
                    .font(.caption)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: 72)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 6)
            .background {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.primary.opacity(isHovered ? 0.06 : 0))
            }
            .scaleEffect(isHovered ? 1.04 : 1)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
        .onAppear {
            FaviconService.shared.icon(for: favorite.url) { image in
                icon = image
            }
        }
    }

    @ViewBuilder
    private var iconView: some View {
        if let icon {
            Image(nsImage: icon)
                .resizable()
                .frame(width: 36, height: 36)
        } else {
            Image(systemName: "globe")
                .font(.system(size: 20))
                .foregroundStyle(.secondary)
                .frame(width: 36, height: 36)
        }
    }
}
