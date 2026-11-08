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
            Spacer()
            VStack(spacing: 28) {
                if !greetingIsHidden {
                    greeting
                }

                searchField

                favoritesRow
            }
            Spacer()
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
        VStack(spacing: 14) {
            Image("OpenMxcLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))

            Text(Self.greetingText)
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(.primary)
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            TextField("Search or enter address", text: $searchText)
                .textFieldStyle(.plain)
                .font(.body)
                .onSubmit {
                    controller.navigate(to: searchText)
                    searchText = ""
                }
        }
        .padding(.horizontal, 16)
        .frame(width: 520, height: 40)
        .background(Color(nsColor: .textBackgroundColor), in: Capsule())
        .overlay {
            Capsule()
                .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 0.5)
        }
    }

    @ViewBuilder
    private var favoritesRow: some View {
        if controller.favorites.favorites.isEmpty {
            Text("No favorites yet. Add sites from the toolbar to see them here.")
                .font(.callout)
                .foregroundStyle(.secondary)
        } else {
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
            VStack(spacing: 6) {
                iconView
                Text(favorite.title)
                    .font(.caption)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: 72)
            }
            .padding(.vertical, 8)
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
                .frame(width: 36, height: 36)
        } else {
            Image(systemName: "globe")
                .font(.system(size: 20))
                .foregroundStyle(.secondary)
                .frame(width: 36, height: 36)
        }
    }
}
