import SwiftUI

struct BrowserToolbar: View {
    @Environment(BrowserController.self) private var controller

    var body: some View {
        HStack(spacing: 8) {
            disabledButton("chevron.left", help: "Back")
            disabledButton("chevron.right", help: "Forward")
            disabledButton("arrow.clockwise", help: "Reload")

            addressField

            disabledButton("plus", help: "New Tab")

            Button {
                controller.toggleSidebar()
            } label: {
                Image(systemName: "sidebar.left")
            }
            .buttonStyle(.borderless)
            .help("Toggle Sidebar")
        }
        .padding(.horizontal, 12)
        .frame(height: BrowserConstants.toolbarHeight)
    }

    private var addressField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.tertiary)
            Text("Search or enter address")
                .foregroundStyle(.secondary)
        }
        .font(.body)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
        .frame(height: 30)
        .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color(nsColor: .separatorColor), lineWidth: 0.5)
        }
        .allowsHitTesting(false)
    }

    private func disabledButton(_ symbol: String, help: String) -> some View {
        Button {} label: {
            Image(systemName: symbol)
        }
        .buttonStyle(.borderless)
        .help(help)
        .disabled(true)
    }
}
