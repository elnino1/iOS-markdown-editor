import SwiftUI
import Combine

struct EditorView: View {
    @EnvironmentObject private var appState: AppState
    @State private var saveTimer: AnyCancellable? = nil
    @State private var showUnsavedAlert = false
    @State private var showSaveError = false
    @State private var pendingURL: URL? = nil

    private var document: MarkdownDocument? { appState.document }

    var body: some View {
        NavigationStack {
            Group {
                if let doc = document {
                    MarkdownTextEditor(
                        text: Binding(
                            get: { doc.text },
                            set: { newValue in
                                doc.text = newValue
                                scheduleSave(for: doc)
                            }
                        )
                    )
                    .ignoresSafeArea(.keyboard)
                } else {
                    Text("No file open")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(buildTitle())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        closeEditor()
                    }
                }
            }
            .onChange(of: appState.pendingOpenURL) { url in
                guard let url else { return }
                if let doc = document, doc.hasUnsavedChanges {
                    pendingURL = url
                    showUnsavedAlert = true
                } else {
                    // No unsaved changes — open directly
                    appState.closeCurrentDocument {
                        appState.openAfterResolvingConflict(url: url)
                    }
                }
            }
        }
        .alert("Unsaved Changes", isPresented: $showUnsavedAlert) {
            Button("Save") {
                saveImmediately {
                    if let url = pendingURL {
                        appState.openAfterResolvingConflict(url: url)
                    }
                    pendingURL = nil
                }
            }
            Button("Discard", role: .destructive) {
                if let url = pendingURL {
                    appState.closeCurrentDocument {
                        appState.openAfterResolvingConflict(url: url)
                    }
                }
                pendingURL = nil
            }
            Button("Cancel", role: .cancel) {
                appState.pendingOpenURL = nil
                pendingURL = nil
            }
        } message: {
            Text("Save changes before opening a new file?")
        }
        .alert("Save Failed", isPresented: $showSaveError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(FileOperationError.saveFailed.message)
        }
    }

    // MARK: - Auto-save

    /// Debounce: cancel any pending save, schedule a new one 1.5s after last keystroke
    private func scheduleSave(for doc: MarkdownDocument) {
        saveTimer?.cancel()
        saveTimer = Just(())
            .delay(for: .seconds(1.5), scheduler: RunLoop.main)
            .sink { _ in
                // Calling updateChangeCount(.done) marks the document as changed,
                // which triggers UIDocument's built-in auto-save mechanism.
                // UIDocument will call contents(forType:) and write to disk.
                doc.updateChangeCount(.done)
            }
    }

    // MARK: - Immediate save (for alert "Save" action)

    private func saveImmediately(completion: @escaping () -> Void) {
        guard let doc = document else {
            completion()
            return
        }
        saveTimer?.cancel()
        doc.save(to: doc.fileURL, for: .forOverwriting) { success in
            if !success {
                Task { @MainActor in
                    self.showSaveError = true
                }
            }
            completion()
        }
    }

    // MARK: - Title

    /// Returns filename with " *" suffix when document has unsaved changes.
    /// Reads UIDocument.hasUnsavedChanges directly each time view re-renders.
    /// View re-renders when doc.text changes via the Binding setter above, so
    /// the title updates on each keystroke debounce cycle.
    private func buildTitle() -> String {
        let filename = document?.fileURL.lastPathComponent ?? "Editor"
        let unsavedMarker = (document?.hasUnsavedChanges ?? false) ? " *" : ""
        return filename + unsavedMarker
    }

    // MARK: - Close

    private func closeEditor() {
        saveTimer?.cancel()
        appState.closeCurrentDocument()
    }
}
