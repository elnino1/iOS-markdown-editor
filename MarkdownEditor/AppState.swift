import Foundation
import Combine

@MainActor
class AppState: ObservableObject {
    @Published var document: MarkdownDocument? = nil
    @Published var isEditorPresented: Bool = false
    @Published var pendingOpenURL: URL? = nil  // signals EditorView to show unsaved-changes alert

    func open(url: URL) {
        if let existingDoc = document, existingDoc.hasUnsavedChanges {
            // There's an open document with unsaved changes.
            // Signal EditorView to show the unsaved-changes alert.
            pendingOpenURL = url
            return
        }
        _openDirectly(url: url)
    }

    func openAfterResolvingConflict(url: URL) {
        // Called by EditorView after user picks Save or Discard
        pendingOpenURL = nil
        _openDirectly(url: url)
    }

    private func _openDirectly(url: URL) {
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
            isEditorPresented = false
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
