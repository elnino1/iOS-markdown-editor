import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    @State private var isPickerPresented = false

    var body: some View {
        NavigationStack {
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
                    #if targetEnvironment(simulator)
                    // .fileImporter callback never fires on iOS 26 simulator.
                    // UIDocumentPickerViewController presented from window root VC
                    // at least opens the picker; try deprecated init for a different code path.
                    DocumentPickerPresenter.present { url in
                        print("HomeView: simulator picker selected \(url.lastPathComponent)")
                        appState.open(url: url)
                    }
                    #else
                    isPickerPresented = true
                    #endif
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(minWidth: 44, minHeight: 44)

                Spacer()
            }
            .padding(24)
            .navigationTitle("Markdown Editor")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $appState.isEditorPresented) {
                EditorView()
                    .environmentObject(appState)
            }
            // Real device: .fileImporter works correctly on iOS 26
            .fileImporter(
                isPresented: $isPickerPresented,
                allowedContentTypes: [
                    UTType(filenameExtension: "md") ?? .plainText,
                    UTType(filenameExtension: "markdown") ?? .plainText
                ],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    print("HomeView: fileImporter selected \(url.lastPathComponent)")
                    appState.open(url: url)
                case .failure(let error):
                    print("HomeView: fileImporter error — \(error)")
                }
            }
        }
    }
}

// MARK: - Simulator picker (iOS 26 workaround)

/// Presents UIDocumentPickerViewController from the window root VC using the
/// deprecated string-based initializer — different internal code path from
/// init(forOpeningContentTypes:), which may behave differently on iOS 26 simulator.
enum DocumentPickerPresenter {
    private static var activeCoordinator: Coordinator?

    static func present(onPick: @escaping (URL) -> Void) {
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
