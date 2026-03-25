import Foundation
import Combine

@MainActor
class AppState: ObservableObject {
    @Published var document: MarkdownDocument? = nil
    @Published var isEditorPresented: Bool = false

    // Opens a security-scoped URL using UIDocument coordination
    func open(url: URL) {
        // Close any existing document before opening a new one.
        // The unsaved-changes alert logic lives in EditorView (Plan 03)
        // and calls this only after the user resolves any pending changes.
        let doc = MarkdownDocument(fileURL: url)
        doc.open { [weak self] success in
            // UIDocument callbacks may arrive on any thread; dispatch to main actor.
            Task { @MainActor [weak self] in
                guard let self else { return }
                if success {
                    self.document = doc
                    self.isEditorPresented = true
                }
            }
        }
    }

    func closeCurrentDocument(completion: (() -> Void)? = nil) {
        guard let doc = document else {
            completion?()
            return
        }
        doc.close { [weak self] _ in
            // UIDocument callbacks may arrive on any thread; dispatch to main actor.
            Task { @MainActor [weak self] in
                self?.document = nil
                self?.isEditorPresented = false
                completion?()
            }
        }
    }
}
