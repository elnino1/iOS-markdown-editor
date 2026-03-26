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
            // Zero-size bridge that presents UIDocumentPickerViewController as a true modal.
            // SwiftUI .fileImporter and .sheet-embedded UIViewControllerRepresentable
            // both fail to fire the delegate on iOS 26 — presenting directly works.
            .background(
                DocumentPickerBridge(isPresented: $isPickerPresented) { url in
                    print("HomeView: picker selected \(url.lastPathComponent)")
                    appState.open(url: url)
                }
            )
        }
    }
}

// MARK: - DocumentPickerBridge

/// Presents UIDocumentPickerViewController as a true UIKit modal from the hosting
/// view controller. Avoids SwiftUI sheet embedding which prevents the delegate from firing.
private struct DocumentPickerBridge: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let onPick: (URL) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(bridge: self) }

    func makeUIViewController(context: Context) -> UIViewController {
        context.coordinator.host
    }

    func updateUIViewController(_ vc: UIViewController, context: Context) {
        guard isPresented, vc.presentedViewController == nil else { return }
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        vc.present(picker, animated: true)
    }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        /// Thin host VC — SwiftUI adds it to the hierarchy, giving us a presentation context.
        let host = UIViewController()
        var bridge: DocumentPickerBridge

        init(bridge: DocumentPickerBridge) { self.bridge = bridge }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            bridge.isPresented = false
            guard let url = urls.first else { return }
            bridge.onPick(url)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            print("HomeView: picker cancelled")
            bridge.isPresented = false
        }
    }
}
