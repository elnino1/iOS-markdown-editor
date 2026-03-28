import SwiftUI

/// Placeholder root view — replaced by HomeView in Plan 02.
struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("Markdown Editor")
                .font(.largeTitle)
                .bold()

            Text("Open a markdown file to get started")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
