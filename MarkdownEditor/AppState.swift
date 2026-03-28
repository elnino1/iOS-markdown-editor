import Foundation
import Combine

// MARK: - FileOperationError

enum FileOperationError: Identifiable {
    case permissionDenied
    case fileNotFound
    case unreadable
    case saveFailed
    case unknown

    var id: String { title }

    var title: String { "Couldn't Open File" }

    var message: String {
        switch self {
        case .permissionDenied: return "You don't have permission to open this file."
        case .fileNotFound:     return "The file could not be found. It may have been moved or deleted."
        case .unreadable:       return "Couldn't read this file. It may be damaged or in an unsupported format."
        case .saveFailed:       return "Changes couldn't be saved. Check that the file is still accessible."
        case .unknown:          return "Something went wrong. Please try again."
        }
    }

    static func from(_ error: Error) -> FileOperationError {
        let code = (error as? CocoaError)?.code
        switch code {
        case .fileReadNoPermission, .fileWriteNoPermission:
            return .permissionDenied
        case .fileNoSuchFile, .fileReadNoSuchFile:
            return .fileNotFound
        case .fileReadCorruptFile, .fileReadUnknown:
            return .unreadable
        default:
            return .unknown
        }
    }
}

// MARK: - AppState

@MainActor
class AppState: ObservableObject {
    @Published var document: MarkdownDocument? = nil
    @Published var isEditorPresented: Bool = false
    @Published var pendingOpenURL: URL? = nil  // signals EditorView to show unsaved-changes alert
    @Published var openError: FileOperationError? = nil   // non-nil triggers error alert in HomeView
    @Published var largeFileWarning: Bool = false         // true when opened file > 500 KB
    @Published var encodingFallbackWarning: Bool = false  // true when latin1 fallback was used

    let recentFiles = RecentFilesStore()

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
                    // Check file size: warn if > 500 KB (512_000 bytes in utf8 approximation)
                    let byteCount = doc.text.utf8.count
                    self.largeFileWarning = byteCount > 512_000
                    // Check encoding fallback
                    self.encodingFallbackWarning = doc.usedEncodingFallback
                    // Record in recent files
                    self.recentFiles.add(url: url)
                } else {
                    // Open failed — release security-scoped resource, surface error to user
                    self.securityScopedURL?.stopAccessingSecurityScopedResource()
                    self.securityScopedURL = nil
                    // UIDocument.open does not expose the underlying error directly;
                    // surface a generic open failure to the user.
                    self.openError = .unknown
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
                self?.largeFileWarning = false
                self?.encodingFallbackWarning = false
                scopedURL?.stopAccessingSecurityScopedResource()
                completion?()
            }
        }
    }
}
