import Foundation
import Combine

@MainActor
class AppState: ObservableObject {
    @Published var document: MarkdownDocument? = nil
    @Published var isEditorPresented: Bool = false
    @Published var pendingOpenURL: URL? = nil  // signals EditorView to show unsaved-changes alert

    // Retain the security-scoped URL so we can stop access when the document closes
    private var securityScopedURL: URL? = nil

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
        // fileImporter returns a security-scoped URL. Must call startAccessingSecurityScopedResource()
        // before UIDocument can read the file; stop after the document is closed.
        let accessed = url.startAccessingSecurityScopedResource()
        securityScopedURL = accessed ? url : nil
        print("AppState: opening \(url.lastPathComponent) — securityScoped=\(accessed)")

        let doc = MarkdownDocument(fileURL: url)
        doc.open { [weak self] success in
            // UIDocument callbacks may arrive on any thread; dispatch to main actor.
            Task { @MainActor [weak self] in
                guard let self else { return }
                print("AppState: UIDocument.open completed — success=\(success)")
                if success {
                    self.document = doc
                    self.isEditorPresented = true
                } else {
                    // Open failed — release the security-scoped resource immediately
                    self.securityScopedURL?.stopAccessingSecurityScopedResource()
                    self.securityScopedURL = nil
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
        let scopedURL = securityScopedURL
        doc.close { [weak self] _ in
            // UIDocument callbacks may arrive on any thread; dispatch to main actor.
            Task { @MainActor [weak self] in
                self?.document = nil
                self?.isEditorPresented = false
                self?.securityScopedURL = nil
                scopedURL?.stopAccessingSecurityScopedResource()
                completion?()
            }
        }
    }
}
