import SwiftUI

@main
struct MarkdownEditorApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onOpenURL { url in
                    appState.open(url: url)
                }
        }
    }
}
