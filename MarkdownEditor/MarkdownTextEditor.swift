// MarkdownEditor/MarkdownTextEditor.swift
import SwiftUI
import UIKit
import Combine

/// UITextView wrapped as SwiftUI component with live markdown syntax highlighting.
/// Uses UIViewRepresentable because iOS 16-25 TextEditor ignores AttributedString binding.
struct MarkdownTextEditor: UIViewRepresentable {
    @Binding var text: String
    /// Font size for body text (non-heading elements)
    var font: UIFont = UIFont.preferredFont(forTextStyle: .body).withSize(16)

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.delegate = context.coordinator
        tv.font = font
        tv.isScrollEnabled = true
        tv.isEditable = true
        tv.isSelectable = true
        tv.backgroundColor = UIColor.systemBackground  // adapts light/dark automatically
        tv.textColor = UIColor.label                   // adapts light/dark automatically
        tv.autocorrectionType = .default
        tv.autocapitalizationType = .sentences
        tv.smartDashesType = .no    // prevent iOS from "correcting" markdown -- chars
        tv.smartQuotesType = .no    // prevent iOS from curling quotes in code spans
        // Apply initial highlighting
        tv.attributedText = makeAttributedString(from: text, baseFont: font)
        return tv
    }

    func updateUIView(_ tv: UITextView, context: Context) {
        // Only update if text changed externally (not from user typing)
        // Avoid resetting cursor position during user edits
        guard tv.text != text else { return }
        let selectedRange = tv.selectedRange
        tv.attributedText = makeAttributedString(from: text, baseFont: font)
        tv.selectedRange = selectedRange
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, font: font)
    }

    // MARK: - Attributed string builder

    private func makeAttributedString(from text: String, baseFont: UIFont) -> NSAttributedString {
        let attrString = HighlightingService.applyMarkdownColors(to: text)
        // Convert AttributedString -> NSAttributedString for UITextView
        let nsAttrString = NSMutableAttributedString(attrString)
        // Set base font for any range without explicit font attribute
        nsAttrString.addAttribute(
            .font, value: baseFont,
            range: NSRange(location: 0, length: nsAttrString.length)
        )
        return nsAttrString
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
            // Update plain text binding immediately (triggers auto-save in EditorView)
            text = textView.text

            // Debounce highlighting: wait 300ms after typing stops before re-applying colors
            // This avoids running regex on every keystroke for large files (Pitfall 4)
            highlightTimer?.cancel()
            highlightTimer = Just(())
                .delay(for: .seconds(0.3), scheduler: RunLoop.main)
                .sink { [weak textView, weak self] _ in
                    guard let textView, let self else { return }
                    let selectedRange = textView.selectedRange
                    let attrString = HighlightingService.applyMarkdownColors(to: self.text)
                    let nsAttrString = NSMutableAttributedString(attrString)
                    nsAttrString.addAttribute(
                        .font, value: self.font,
                        range: NSRange(location: 0, length: nsAttrString.length)
                    )
                    textView.attributedText = nsAttrString
                    textView.selectedRange = selectedRange  // restore cursor position
                }
        }
    }
}
