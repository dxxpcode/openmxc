import AppKit
import SwiftUI

struct StartPageView: View {
    @Environment(BrowserController.self) private var controller
    @AppStorage("startPageGreetingHidden") private var greetingIsHidden = false

    @State private var searchText = ""
    @State private var editingFavorite: Favorite?
    @State private var editedAddress = ""

    var body: some View {
        VStack(spacing: 28) {
            if !greetingIsHidden {
                greeting
            }

            searchField

            favoritesSection
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
        .overlay(alignment: .topTrailing) {
            if !greetingIsHidden {
                Button {
                    greetingIsHidden = true
                } label: {
                    Image(systemName: "eye.slash")
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
                .help("Hide Greeting")
                .padding(12)
            }
        }
        .alert("Edit Address", isPresented: Binding(
            get: { editingFavorite != nil },
            set: { if !$0 { editingFavorite = nil } }
        )) {
            TextField("Address", text: $editedAddress)
            Button("Cancel", role: .cancel) { editingFavorite = nil }
            Button("Save") { saveEditedAddress() }
        }
    }

    private var greeting: some View {
        VStack(spacing: 10) {
            Image("OpenMxcLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))

            Text(Self.greetingText)
                .font(.system(size: 22, weight: .medium))
        }
        .padding(.top, 40)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search or enter address", text: $searchText)
                .textFieldStyle(.plain)
                .onSubmit {
                    controller.navigate(to: searchText)
                    searchText = ""
                }
        }
        .padding(.horizontal, 12)
        .frame(width: 420, height: 34)
        .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 0.5)
        }
    }

    @ViewBuilder
    private var favoritesSection: some View {
        if controller.favorites.favorites.isEmpty {
            Text("No favorites yet. Add sites from the toolbar to see them here.")
                .font(.callout)
                .foregroundStyle(.secondary)
        } else {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 110, maximum: 140), spacing: 16)],
                spacing: 20
            ) {
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
                        Button("Move Left") {
                            controller.favorites.move(favorite, before: neighbor(of: favorite, offset: -1) ?? favorite)
                        }
                        .disabled(!canMove(favorite, offset: -1))
                        Button("Move Right") {
                            controller.favorites.move(favorite, before: neighbor(of: favorite, offset: 1) ?? favorite)
                        }
                        .disabled(!canMove(favorite, offset: 1))
                        Divider()
                        Button("Remove Favorite", role: .destructive) {
                            controller.favorites.remove(favorite)
                        }
                    }
                }
            }
            .frame(maxWidth: 560)
        }
    }

    private func neighbor(of favorite: Favorite, offset: Int) -> Favorite? {
        let favorites = controller.favorites.favorites
        guard let index = favorites.firstIndex(where: { $0.id == favorite.id }) else { return nil }
        let target = index + offset
        guard favorites.indices.contains(target) else { return nil }
        return favorites[target]
    }

    private func canMove(_ favorite: Favorite, offset: Int) -> Bool {
        neighbor(of: favorite, offset: offset) != nil
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

    private static var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Good night"
        }
    }
}

private struct FavoriteTileView: View {
    let favorite: Favorite
    let action: () -> Void

    @State private var icon: NSImage?

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                iconView
                Text(favorite.title)
                    .font(.callout)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
                .frame(width: 32, height: 32)
        } else {
            Image(systemName: "globe")
                .font(.system(size: 24))
                .foregroundStyle(.secondary)
                .frame(width: 32, height: 32)
        }
    }
}
