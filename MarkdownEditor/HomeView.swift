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
                    isPickerPresented = true
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
            // UIDocumentPickerViewController via sheet — more reliable than .fileImporter on iOS 26
            .sheet(isPresented: $isPickerPresented) {
                DocumentPicker { url in
                    print("HomeView: DocumentPicker selected \(url.lastPathComponent)")
                    isPickerPresented = false
                    appState.open(url: url)
                } onCancel: {
                    print("HomeView: DocumentPicker cancelled")
                    isPickerPresented = false
                }
                .ignoresSafeArea()
            }
        }
    }
}

// MARK: - UIDocumentPickerViewController wrapper

/// Wraps UIDocumentPickerViewController directly — bypasses SwiftUI .fileImporter
/// which does not fire its result callback reliably on iOS 26 simulator.
private struct DocumentPicker: UIViewControllerRepresentable {
    let onPick: (URL) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick, onCancel: onCancel) }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        let onCancel: () -> Void

        init(onPick: @escaping (URL) -> Void, onCancel: @escaping () -> Void) {
            self.onPick = onPick
            self.onCancel = onCancel
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onPick(url)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onCancel()
        }
    }
}
