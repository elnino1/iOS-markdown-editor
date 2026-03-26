// MarkdownEditor/MarkdownTextEditor.swift
import SwiftUI
import UIKit
import Combine

/// UITextView wrapped as SwiftUI component with live markdown syntax highlighting.
/// Uses UIViewRepresentable because iOS 16-25 TextEditor ignores AttributedString binding.
struct MarkdownTextEditor: UIViewRepresentable {
    @Binding var text: String
    var font: UIFont = UIFont.preferredFont(forTextStyle: .body).withSize(16)

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.delegate = context.coordinator
        tv.isScrollEnabled = true
        tv.isEditable = true
        tv.isSelectable = true
        tv.backgroundColor = UIColor.systemBackground
        tv.autocorrectionType = .default
        tv.autocapitalizationType = .sentences
        tv.smartDashesType = .no
        tv.smartQuotesType = .no
        tv.attributedText = HighlightingService.applyMarkdownColors(to: text, baseFont: font)
        return tv
    }

    func updateUIView(_ tv: UITextView, context: Context) {
        guard tv.text != text else { return }
        let selectedRange = tv.selectedRange
        tv.attributedText = HighlightingService.applyMarkdownColors(to: text, baseFont: font)
        tv.selectedRange = selectedRange
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, font: font)
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, UITextViewDelegate {
        @Binding var text: String
        let font: UIFont
        private var highlightTimer: AnyCancellable?

        init(text: Binding<String>, font: UIFont) {
            _text = text
            self.font = font
        }

        func textViewDidChange(_ textView: UITextView) {
            text = textView.text

            // Debounce highlighting: 300ms after typing stops
            highlightTimer?.cancel()
            highlightTimer = Just(())
                .delay(for: .seconds(0.3), scheduler: RunLoop.main)
                .sink { [weak textView, weak self] _ in
                    guard let textView, let self else { return }
                    let selectedRange = textView.selectedRange
                    textView.attributedText = HighlightingService.applyMarkdownColors(
                        to: self.text, baseFont: self.font
                    )
                    textView.selectedRange = selectedRange
                }
        }
    }
}
