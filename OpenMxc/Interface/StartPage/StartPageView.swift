import AppKit
import SwiftUI

struct StartPageView: View {
    @Environment(BrowserController.self) private var controller
    @AppStorage("startPageGreetingHidden") private var greetingIsHidden = false

    @State private var searchText = ""
    @State private var editingFavorite: Favorite?
    @State private var editedAddress = ""

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 80)
            greetingSection
            searchField
                .padding(.top, 32)
            favoritesSection
                .padding(.top, 40)
            Spacer(minLength: 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
        .overlay(alignment: .topTrailing) {
            if !greetingIsHidden {
                Button {
                    greetingIsHidden = true
                } label: {
                    Image(systemName: "eye.slash")
                }
                .buttonStyle(.glassIcon)
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

    @ViewBuilder
    private var greetingSection: some View {
        if !greetingIsHidden {
            VStack(spacing: 14) {
                Image("OpenMxcLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))

                Text(Self.greetingText)
                    .font(.system(size: 26, weight: .medium))
            }
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
            TextField("Search or enter address", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 15))
                .onSubmit {
                    controller.navigate(to: searchText)
                    searchText = ""
                }
        }
        .padding(.horizontal, 16)
        .frame(width: 520, height: 42)
        .glassField(cornerRadius: 14)
    }

    @ViewBuilder
    private var favoritesSection: some View {
        if controller.favorites.favorites.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "star")
                    .font(.system(size: 30, weight: .light))
                    .foregroundStyle(.tertiary)
                Text("No favorites yet")
                    .font(.headline)
                Text("Tap the star in the toolbar to save a site here.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 8)
        } else {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 120, maximum: 150), spacing: 18)],
                spacing: 22
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
            .frame(maxWidth: 620)
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
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                iconView
                Text(favorite.title)
                    .font(.callout)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 8)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isHovered ? Color.primary.opacity(0.07) : .clear)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
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
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        } else {
            Image(systemName: "globe")
                .font(.system(size: 26))
                .foregroundStyle(.secondary)
                .frame(width: 44, height: 44)
                .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}
