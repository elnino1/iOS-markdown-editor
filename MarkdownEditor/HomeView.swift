import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct HomeView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            Group {
                if appState.recentFiles.entries.isEmpty {
                    emptyStateView
                } else {
                    recentFilesListView
                }
            }
            .navigationTitle("Markdown Editor")
            .navigationBarTitleDisplayMode(.inline)
            .alert(
                appState.openError?.title ?? "Error",
                isPresented: Binding(
                    get: { appState.openError != nil },
                    set: { if !$0 { appState.openError = nil } }
                )
            ) {
                Button("Try Again") {
                    appState.openError = nil
                    openFilePicker()
                }
                Button("Cancel", role: .cancel) {
                    appState.openError = nil
                }
            } message: {
                Text(appState.openError?.message ?? "")
            }
            .sheet(isPresented: $appState.isEditorPresented) {
                EditorView()
                    .environmentObject(appState)
            }
        }
    }

    // MARK: - Empty state (no recent files)

    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "doc.text")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("Markdown Editor")
                    .font(.title2.weight(.semibold))
                Text("Open a markdown file to get started")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button("Open File") {
                openFilePicker()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(minWidth: 44, minHeight: 44)

            Spacer()
        }
        .padding(24)
    }

    // MARK: - Recent files list

    private var recentFilesListView: some View {
        List {
            Section {
                Button("Open Other File...") {
                    openFilePicker()
                }
                .frame(minHeight: 44)
            }
            Section("Recent") {
                ForEach(appState.recentFiles.entries) { entry in
                    Button {
                        if let url = appState.recentFiles.resolve(entry) {
                            appState.open(url: url)
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.filename)
                                .font(.body)
                                .foregroundStyle(.primary)
                            Text(entry.lastOpenedAt, style: .relative)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(minHeight: 44)
                    }
                }
                .onDelete { offsets in
                    appState.recentFiles.remove(at: offsets)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Picker action

    private func openFilePicker() {
        #if targetEnvironment(simulator)
        // .fileImporter callback never fires on iOS 26 simulator.
        // UIDocumentPickerViewController presented from window root VC
        // at least opens the picker; try deprecated init for a different code path.
        DocumentPickerPresenter.presentLegacy { url in
            print("HomeView: simulator picker selected \(url.lastPathComponent)")
            appState.open(url: url)
        }
        #else
        // Present UIDocumentPickerViewController directly via UIKit.
        // Avoids SwiftUI sheet-stacking conflicts (e.g. tapping "Open Other File"
        // right after the editor sheet dismisses) and starts at the Files app root
        // rather than the app's sandbox folder.
        DocumentPickerPresenter.present { url in
            print("HomeView: picker selected \(url.lastPathComponent)")
            appState.open(url: url)
        }
        #endif
    }
}

// MARK: - UIKit document picker presenter

/// Presents UIDocumentPickerViewController directly from the key window's top
/// view controller, bypassing SwiftUI's sheet stack. This avoids a race condition
/// where SwiftUI won't present a new sheet while a previous sheet is still
/// mid-dismiss. It also lets the system start at the Files app root rather than
/// the app's sandbox folder.
enum DocumentPickerPresenter {
    private static var activeCoordinator: Coordinator?

    /// Real device: modern UTType-based initializer, starts at Files app root.
    static func present(onPick: @escaping (URL) -> Void) {
        guard let presenter = topViewController() else {
            print("DocumentPickerPresenter: no presenter found")
            return
        }
        let coordinator = Coordinator(onPick: onPick)
        activeCoordinator = coordinator

        let types: [UTType] = [
            UTType(filenameExtension: "md") ?? .plainText,
            UTType(filenameExtension: "markdown") ?? .plainText
        ]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        picker.delegate = coordinator
        picker.allowsMultipleSelection = false
        picker.shouldShowFileExtensions = true
        print("DocumentPickerPresenter: presenting from \(type(of: presenter))")
        presenter.present(picker, animated: true)
    }

    /// Simulator (iOS 26 workaround): deprecated string-based initializer uses a
    /// different internal code path that at least opens the picker, since the
    /// modern init's callback never fires on the iOS 26 simulator.
    static func presentLegacy(onPick: @escaping (URL) -> Void) {
        guard let presenter = topViewController() else {
            print("DocumentPickerPresenter: no presenter found")
            return
        }
        let coordinator = Coordinator(onPick: onPick)
        activeCoordinator = coordinator

        // Deprecated API — uses UTI strings and .open mode directly
        let picker = UIDocumentPickerViewController(
            documentTypes: ["net.daringfireball.markdown", "public.plain-text"],
            in: .open
        )
        picker.delegate = coordinator
        picker.allowsMultipleSelection = false
        picker.shouldShowFileExtensions = true
        print("DocumentPickerPresenter: presenting from \(type(of: presenter))")
        presenter.present(picker, animated: true)
    }

    private static func topViewController() -> UIViewController? {
        guard
            let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
            let window = scene.keyWindow
        else { return nil }
        var top = window.rootViewController
        while let presented = top?.presentedViewController { top = presented }
        return top
    }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        init(onPick: @escaping (URL) -> Void) { self.onPick = onPick }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            DocumentPickerPresenter.activeCoordinator = nil
            guard let url = urls.first else { return }
            onPick(url)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            print("DocumentPickerPresenter: cancelled")
            DocumentPickerPresenter.activeCoordinator = nil
        }
    }
}
