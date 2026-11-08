import SwiftUI

@Observable
@MainActor
final class BrowserController {
    let navigation = NavigationManager()

    var sidebarIsVisible = true
    private(set) var sidebarWidth: CGFloat = BrowserConstants.sidebarDefaultWidth

    func toggleSidebar() {
        withAnimation(.easeInOut(duration: 0.2)) {
            sidebarIsVisible.toggle()
        }
    }

    func setSidebarWidth(_ width: CGFloat) {
        sidebarWidth = min(
            max(width, BrowserConstants.sidebarMinimumWidth),
            BrowserConstants.sidebarMaximumWidth
        )
    }

    func navigate(to input: String) {
        guard let url = SearchService.resolve(input) else { return }
        navigation.load(url)
    }
}
