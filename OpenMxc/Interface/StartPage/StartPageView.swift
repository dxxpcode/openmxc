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
            Spacer(minLength: 60)
            VStack(spacing: 28) {
                if !greetingIsHidden {
                    greeting
                }

                searchField

                favoritesSection
            }
            Spacer(minLength: 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(OX.background)
        .padding(.horizontal, 32)
        .overlay(alignment: .topTrailing) {
            if !greetingIsHidden {
                Button {
                    greetingIsHidden = true
                } label: {
                    Image(systemName: "eye.slash")
                }
                .buttonStyle(.oxIcon)
                .foregroundStyle(OX.textMuted)
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
        HStack(spacing: 10) {
            Text("$")
                .font(OX.mono(.title2, weight: .bold))
                .foregroundStyle(OX.accent)
            Text("\(Self.greetingText.lowercased()) — openmxc")
                .font(OX.mono(.title3, weight: .medium))
                .foregroundStyle(OX.textPrimary)
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11))
                .foregroundStyle(OX.textMuted)
            TextField("url or search query", text: $searchText)
                .textFieldStyle(.plain)
                .font(OX.mono(.callout))
                .foregroundStyle(OX.textPrimary)
                .onSubmit {
                    controller.navigate(to: searchText)
                    searchText = ""
                }
        }
        .padding(.horizontal, 14)
        .frame(width: 520, height: 36)
        .background(OX.surface, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .strokeBorder(OX.border, lineWidth: 1)
        }
    }

    @ViewBuilder
    private var favoritesSection: some View {
        if controller.favorites.favorites.isEmpty {
            Text("no favorites — press ⌘D on any page to pin one here")
                .font(OX.mono(.callout))
                .foregroundStyle(OX.textMuted)
        } else {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 120, maximum: 150), spacing: 14)],
                spacing: 14
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
            HStack(spacing: 10) {
                iconView
                VStack(alignment: .leading, spacing: 2) {
                    Text(favorite.title)
                        .font(OX.mono(.callout))
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text(favorite.url.host() ?? favorite.url.absoluteString)
                        .font(OX.monoSmall)
                        .foregroundStyle(OX.textMuted)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(isHovered ? OX.surfaceRaised : OX.surface)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(isHovered ? OX.accent.opacity(0.5) : OX.border, lineWidth: 1)
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
                .frame(width: 20, height: 20)
        } else {
            Image(systemName: "globe")
                .font(.system(size: 12))
                .foregroundStyle(OX.textMuted)
                .frame(width: 20, height: 20)
        }
    }
}
