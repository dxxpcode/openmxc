import SwiftUI

struct ContentAreaView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image("OpenMxcLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Text(BrowserConfiguration.applicationName)
                .font(.system(size: 28, weight: .semibold))

            Text("A quiet place to browse.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
