// MarkdownEditor/FormattingService.swift
import UIKit

// MARK: - UITextView helper for UITextRange bridging

private extension UITextView {
    /// Convert NSRange to UITextRange using the text position API.
    /// UITextRange cannot be constructed directly — this extension bridges NSRange.
    func uiTextRange(from nsRange: NSRange) -> UITextRange? {
        guard let start = position(from: beginningOfDocument, offset: nsRange.location),
              let end = position(from: start, offset: nsRange.length) else { return nil }
        return textRange(from: start, to: end)
    }
}

// MARK: - FormattingService

/// Pure formatting logic for toolbar operations.
/// All methods accept a UITextView and operate via UITextInput protocol — never textStorage directly.
/// Each operation wraps changes in beginUndoGrouping/endUndoGrouping for atomic undo.
enum FormattingService {

    // MARK: Bold

    /// Wrap selected text in **markers**, or insert **text** placeholder at cursor.
    static func applyBold(to textView: UITextView) {
        let savedRange = textView.selectedRange
        let ns = textView.text as NSString

        textView.undoManager?.beginUndoGrouping()

        if savedRange.length > 0 {
            let selectedText = ns.substring(with: savedRange)
            let wrapped = "**\(selectedText)**"
            guard let uiRange = textView.uiTextRange(from: savedRange) else {
                textView.undoManager?.endUndoGrouping()
                return
            }
            textView.replace(uiRange, withText: wrapped)
            // Restore selection to the original text (offset by 2 for opening **)
            textView.selectedRange = NSRange(location: savedRange.location + 2,
                                            length: savedRange.length)
        } else {
            textView.insertText("**text**")
            // Select "text" inside the markers (offset 2, length 4)
            textView.selectedRange = NSRange(location: savedRange.location + 2, length: 4)
        }

        textView.undoManager?.endUndoGrouping()
        textView.undoManager?.setActionName("Make Bold")
    }

    // MARK: Italic

    /// Wrap selected text in *markers*, or insert *text* placeholder at cursor.
    static func applyItalic(to textView: UITextView) {
        let savedRange = textView.selectedRange
        let ns = textView.text as NSString

        textView.undoManager?.beginUndoGrouping()

        if savedRange.length > 0 {
            let selectedText = ns.substring(with: savedRange)
            let wrapped = "*\(selectedText)*"
            guard let uiRange = textView.uiTextRange(from: savedRange) else {
                textView.undoManager?.endUndoGrouping()
                return
            }
            textView.replace(uiRange, withText: wrapped)
            // Restore selection to the original text (offset by 1 for opening *)
            textView.selectedRange = NSRange(location: savedRange.location + 1,
                                            length: savedRange.length)
        } else {
            textView.insertText("*text*")
            // Select "text" inside the markers (offset 1, length 4)
            textView.selectedRange = NSRange(location: savedRange.location + 1, length: 4)
        }

        textView.undoManager?.endUndoGrouping()
        textView.undoManager?.setActionName("Make Italic")
    }

    // MARK: Bullet

    /// Prefix the current line (containing the cursor) with "- ".
    /// Uses NSString.lineRange to correctly handle LF, CRLF, and CR line endings.
    static func applyBullet(to textView: UITextView) {
        let savedRange = textView.selectedRange
        let ns = textView.text as NSString

        // lineRange returns the full line including the line terminator
        let lineRange = ns.lineRange(for: savedRange)
        let lineText = ns.substring(with: lineRange)
        let bulletedLine = "- " + lineText

        textView.undoManager?.beginUndoGrouping()

        guard let uiRange = textView.uiTextRange(from: lineRange) else {
            textView.undoManager?.endUndoGrouping()
            return
        }
        textView.replace(uiRange, withText: bulletedLine)

        textView.undoManager?.endUndoGrouping()
        textView.undoManager?.setActionName("Add Bullet")

        // Restore cursor to same relative position within line, shifted by "- " prefix (2)
        textView.selectedRange = NSRange(location: savedRange.location + 2, length: 0)
    }

    // MARK: Table

    /// Insert a 3-column × 2-row markdown table at cursor, or replace selection.
    static func insertTable(to textView: UITextView) {
        let savedRange = textView.selectedRange
        let template = "| Header 1 | Header 2 | Header 3 |\n|----------|----------|----------|\n| Cell 1   | Cell 2   | Cell 3   |"

        textView.undoManager?.beginUndoGrouping()

        if savedRange.length > 0 {
            guard let uiRange = textView.uiTextRange(from: savedRange) else {
                textView.undoManager?.endUndoGrouping()
                return
            }
            textView.replace(uiRange, withText: template)
        } else {
            textView.insertText(template)
        }

        textView.undoManager?.endUndoGrouping()
        textView.undoManager?.setActionName("Insert Table")

        // Position cursor to select "Header 1" (offset 2 from insertion point, length 8)
        textView.selectedRange = NSRange(location: savedRange.location + 2, length: 8)
    }
}
