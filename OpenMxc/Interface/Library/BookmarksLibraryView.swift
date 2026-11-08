import SwiftUI

struct BookmarksLibraryView: View {
    @Environment(BrowserController.self) private var controller

    @State private var searchText = ""
    @State private var newFolderName = ""
    @State private var showNewFolderAlert = false
    @State private var editingBookmark: Bookmark?
    @State private var editedTitle = ""
    @State private var editedURL = ""

    private var store: BookmarkStore { .shared }

    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            listContent
        }
        .alert("New Folder", isPresented: $showNewFolderAlert) {
            TextField("Folder name", text: $newFolderName)
            Button("Cancel", role: .cancel) { newFolderName = "" }
            Button("Create") {
                store.createFolder(name: newFolderName)
                newFolderName = ""
            }
        }
        .alert("Edit Bookmark", isPresented: Binding(
            get: { editingBookmark != nil },
            set: { if !$0 { editingBookmark = nil } }
        )) {
            TextField("Title", text: $editedTitle)
            TextField("Address", text: $editedURL)
            Button("Cancel", role: .cancel) { editingBookmark = nil }
            Button("Save") { saveEditedBookmark() }
        }
    }

    private var toolbar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search bookmarks", text: $searchText)
                .textFieldStyle(.plain)
            }
            .padding(.horizontal, 10)
            .frame(maxWidth: 280, minHeight: 30)
            .glassField(cornerRadius: 9)

            Spacer()

            Button {
                bookmarkCurrentPage()
            } label: {
                Label("Bookmark This Page", systemImage: "plus")
            }
            .disabled(controller.selectedNavigation?.currentURL == nil)

            Button {
                newFolderName = ""
                showNewFolderAlert = true
            } label: {
                Label("New Folder", systemImage: "folder.badge.plus")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var listContent: some View {
        if isSearching {
            bookmarkList(store.allMatching(searchText))
        } else {
            List {
                Section("Bookmarks") {
                    ForEach(store.search("", folderID: nil)) { bookmark in
                        bookmarkRow(bookmark)
                    }
                }
                ForEach(store.childFolders(of: nil)) { folder in
                    Section {
                        ForEach(store.search("", folderID: folder.id)) { bookmark in
                            bookmarkRow(bookmark)
                        }
                    } header: {
                        HStack {
                            Label(folder.name, systemImage: "folder")
                            Spacer()
                            Button {
                                store.deleteFolder(folder)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                            .help("Delete Folder (bookmarks move to top level)")
                        }
                    }
                }
            }
        }
    }

    private func bookmarkList(_ bookmarks: [Bookmark]) -> some View {
        List(bookmarks) { bookmark in
            bookmarkRow(bookmark)
        }
    }

    private func bookmarkRow(_ bookmark: Bookmark) -> some View {
        Button {
            controller.navigate(to: bookmark.url.absoluteString)
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(bookmark.title)
                    .lineLimit(1)
                Text(bookmark.url.host() ?? bookmark.url.absoluteString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Open") {
                controller.navigate(to: bookmark.url.absoluteString)
            }
            Button("Edit…") {
                editedTitle = bookmark.title
                editedURL = bookmark.url.absoluteString
                editingBookmark = bookmark
            }
            Menu("Move to Folder") {
                Button("Top Level") {
                    store.moveBookmark(bookmark, toFolder: nil)
                }
                ForEach(store.folders) { folder in
                    Button(folder.name) {
                        store.moveBookmark(bookmark, toFolder: folder.id)
                    }
                }
            }
            Divider()
            Button("Delete", role: .destructive) {
                store.deleteBookmark(bookmark)
            }
        }
    }

    private func bookmarkCurrentPage() {
        guard let tab = controller.tabManager.selectedTab,
              let url = tab.navigation.currentURL ?? tab.navigation.lastLoadedURL
        else { return }
        store.addBookmark(title: tab.displayTitle, url: url)
    }

    private func saveEditedBookmark() {
        guard let bookmark = editingBookmark,
              let url = SearchService.resolve(editedURL)
        else {
            editingBookmark = nil
            return
        }
        store.updateBookmark(bookmark, title: editedTitle, url: url)
        editingBookmark = nil
    }
}
