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
    var coordinatorBinding: Binding<MarkdownTextEditor.Coordinator?>? = nil

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.delegate = context.coordinator
        context.coordinator.textView = tv
        coordinatorBinding?.wrappedValue = context.coordinator
        tv.isScrollEnabled = true
        tv.isEditable = true
        tv.isSelectable = true
        tv.backgroundColor = UIColor.systemBackground
        tv.autocorrectionType = .default
        tv.autocapitalizationType = .sentences
        tv.smartDashesType = .no
        tv.smartQuotesType = .no
        tv.attributedText = HighlightingService.applyMarkdownColors(to: text, baseFont: font)
        tv.inputAccessoryView = makeAccessoryToolbar(coordinator: context.coordinator)
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
            let highlighted = HighlightingService.applyMarkdownColors(to: text, baseFont: font)
            tv.textStorage.beginEditing()
            tv.textStorage.setAttributedString(highlighted)
            tv.textStorage.endEditing()
        } else {
            tv.text = text
            tv.textColor = UIColor.label
            tv.font = UIFont.monospacedSystemFont(ofSize: 15, weight: .regular)
        }
        tv.selectedRange = selectedRange
        tv.scrollRangeToVisible(selectedRange)
    }

    // MARK: - Accessory Toolbar

    private func makeAccessoryToolbar(coordinator: Coordinator) -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.tintColor = .systemBlue

        let bold = UIBarButtonItem(image: UIImage(systemName: "bold"), style: .plain, target: nil, action: nil)
        bold.primaryAction = UIAction { [weak coordinator] _ in
            coordinator?.applyBold()
        }
        bold.accessibilityLabel = "Make text bold"

        let italic = UIBarButtonItem(image: UIImage(systemName: "italic"), style: .plain, target: nil, action: nil)
        italic.primaryAction = UIAction { [weak coordinator] _ in
            coordinator?.applyItalic()
        }
        italic.accessibilityLabel = "Make text italic"

        let bullet = UIBarButtonItem(image: UIImage(systemName: "list.bullet"), style: .plain, target: nil, action: nil)
        bullet.primaryAction = UIAction { [weak coordinator] _ in
            coordinator?.applyBullet()
        }
        bullet.accessibilityLabel = "Add bullet to line"

        let table = UIBarButtonItem(image: UIImage(systemName: "tablecells"), style: .plain, target: nil, action: nil)
        table.primaryAction = UIAction { [weak coordinator] _ in
            coordinator?.insertTable()
        }
        table.accessibilityLabel = "Insert markdown table"

        let spacer = UIBarButtonItem(systemItem: .flexibleSpace)

        let undo = UIBarButtonItem(image: UIImage(systemName: "arrow.uturn.backward"), style: .plain, target: nil, action: nil)
        undo.primaryAction = UIAction { [weak coordinator] _ in
            coordinator?.undoAction()
        }
        undo.accessibilityLabel = "Undo last change"
        undo.isEnabled = false

        let redo = UIBarButtonItem(image: UIImage(systemName: "arrow.uturn.forward"), style: .plain, target: nil, action: nil)
        redo.primaryAction = UIAction { [weak coordinator] _ in
            coordinator?.redoAction()
        }
        redo.accessibilityLabel = "Redo last undone change"
        redo.isEnabled = false

        let dismiss = UIBarButtonItem(image: UIImage(systemName: "keyboard.chevron.compact.down"), style: .plain, target: nil, action: nil)
        dismiss.primaryAction = UIAction { [weak coordinator] _ in
            coordinator?.textView?.resignFirstResponder()
        }
        dismiss.accessibilityLabel = "Dismiss keyboard"

        toolbar.items = [bold, italic, bullet, table, spacer, undo, redo, dismiss]

        coordinator.undoBarButton = undo
        coordinator.redoBarButton = redo

        return toolbar
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, UITextViewDelegate {
        @Binding var text: String
        let font: UIFont
        var isHighlightingEnabled: Bool
        private var highlightTimer: AnyCancellable?
        weak var textView: UITextView?
        weak var undoBarButton: UIBarButtonItem?
        weak var redoBarButton: UIBarButtonItem?

        init(text: Binding<String>, font: UIFont, isHighlightingEnabled: Bool) {
            _text = text
            self.font = font
            self.isHighlightingEnabled = isHighlightingEnabled
        }

        // MARK: - Formatting Methods

        func applyBold() {
            guard let tv = textView else { return }
            FormattingService.applyBold(to: tv)
            text = tv.text
            refreshUndoState()
        }

        func applyItalic() {
            guard let tv = textView else { return }
            FormattingService.applyItalic(to: tv)
            text = tv.text
            refreshUndoState()
        }

        func applyBullet() {
            guard let tv = textView else { return }
            FormattingService.applyBullet(to: tv)
            text = tv.text
            refreshUndoState()
        }

        func insertTable() {
            guard let tv = textView else { return }
            FormattingService.insertTable(to: tv)
            text = tv.text
            refreshUndoState()
        }

        func undoAction() {
            guard let tv = textView else { return }
            tv.undoManager?.undo()
            text = tv.text
            refreshUndoState()
        }

        func redoAction() {
            guard let tv = textView else { return }
            tv.undoManager?.redo()
            text = tv.text
            refreshUndoState()
        }

        func refreshUndoState() {
            undoBarButton?.isEnabled = textView?.undoManager?.canUndo ?? false
            redoBarButton?.isEnabled = textView?.undoManager?.canRedo ?? false
        }

        // MARK: - UITextViewDelegate

        func textViewDidChange(_ textView: UITextView) {
            text = textView.text
            refreshUndoState()

            guard isHighlightingEnabled else { return }

            // Debounce highlighting: 300ms after typing stops
            highlightTimer?.cancel()
            highlightTimer = Just(())
                .delay(for: .seconds(0.3), scheduler: RunLoop.main)
                .sink { [weak textView, weak self] _ in
                    guard let textView, let self else { return }
                    let selectedRange = textView.selectedRange
                    let highlighted = HighlightingService.applyMarkdownColors(
                        to: self.text, baseFont: self.font
                    )
                    // Only update attributes — never characters.
                    // setAttributedString replaces character data which wipes the undo stack.
                    // Attribute-only edits leave _UITextUndoManager untouched.
                    guard highlighted.length == textView.textStorage.length else { return }
                    textView.textStorage.beginEditing()
                    highlighted.enumerateAttributes(
                        in: NSRange(location: 0, length: highlighted.length),
                        options: []
                    ) { attrs, range, _ in
                        textView.textStorage.setAttributes(attrs, range: range)
                    }
                    textView.textStorage.endEditing()
                    textView.selectedRange = selectedRange
                    textView.scrollRangeToVisible(selectedRange)
                }
        }
    }
}
