import SwiftUI
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
            .fileImporter(
                isPresented: $isPickerPresented,
                allowedContentTypes: [.item],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    appState.open(url: url)
                case .failure(let error):
                    print("File picker error: \(error.localizedDescription)")
                }
            }
        }
    }
}
