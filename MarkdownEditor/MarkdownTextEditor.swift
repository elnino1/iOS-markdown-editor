// MarkdownEditor/MarkdownTextEditor.swift
import SwiftUI
import UIKit
import Combine

/// UITextView wrapped as SwiftUI component with live markdown syntax highlighting.
/// Uses UIViewRepresentable because iOS 16-25 TextEditor ignores AttributedString binding.
struct MarkdownTextEditor: UIViewRepresentable {
    @Binding var text: String
    var font: UIFont = UIFont.preferredFont(forTextStyle: .body).withSize(16)
    var isHighlightingEnabled: Bool = true

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

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, font: font, isHighlightingEnabled: isHighlightingEnabled)
    }

    func updateUIView(_ tv: UITextView, context: Context) {
        // Keep coordinator in sync with current highlighting flag
        context.coordinator.isHighlightingEnabled = isHighlightingEnabled
        guard tv.text != text else { return }
        let selectedRange = tv.selectedRange
        if isHighlightingEnabled {
            tv.attributedText = HighlightingService.applyMarkdownColors(to: text, baseFont: font)
        } else {
            tv.text = text
            tv.textColor = UIColor.label
            tv.font = UIFont.monospacedSystemFont(ofSize: 15, weight: .regular)
        }
        tv.selectedRange = selectedRange
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, UITextViewDelegate {
        @Binding var text: String
        let font: UIFont
        var isHighlightingEnabled: Bool
        private var highlightTimer: AnyCancellable?

        init(text: Binding<String>, font: UIFont, isHighlightingEnabled: Bool) {
            _text = text
            self.font = font
            self.isHighlightingEnabled = isHighlightingEnabled
        }

        func textViewDidChange(_ textView: UITextView) {
            text = textView.text

            guard isHighlightingEnabled else { return }

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
