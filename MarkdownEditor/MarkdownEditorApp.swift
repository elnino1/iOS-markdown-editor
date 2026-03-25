import SwiftUI

@main
struct MarkdownEditorApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(appState)
                .onOpenURL { url in
                    // Called when app is opened via "Open With" from another app.
                    // url is a security-scoped URL provided by the system.
                    // UIDocument.open handles coordination; no manual startAccessingSecurityScopedResource needed.
                    appState.open(url: url)
                }
        }
    }
}
