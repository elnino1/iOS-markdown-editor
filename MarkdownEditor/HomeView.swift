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
                    DocumentPickerPresenter.present { url in
                        print("HomeView: picker selected \(url.lastPathComponent)")
                        appState.open(url: url)
                    }
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
        }
    }
}

// MARK: - DocumentPickerPresenter

/// Presents UIDocumentPickerViewController from the window's root view controller.
/// Keeps a strong reference to the coordinator so the delegate isn't deallocated mid-presentation.
enum DocumentPickerPresenter {

    private static var activeCoordinator: Coordinator?

    static func present(onPick: @escaping (URL) -> Void) {
        guard let presenter = topViewController() else {
            print("DocumentPickerPresenter: could not find presenter")
            return
        }

        let coordinator = Coordinator(onPick: onPick)
        activeCoordinator = coordinator  // retain until delegate fires

        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item])
        picker.delegate = coordinator
        picker.allowsMultipleSelection = false
        print("DocumentPickerPresenter: presenting from \(type(of: presenter))")
        presenter.present(picker, animated: true)
    }

    private static func topViewController() -> UIViewController? {
        guard
            let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
            let window = scene.keyWindow
        else { return nil }

        var top = window.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
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
