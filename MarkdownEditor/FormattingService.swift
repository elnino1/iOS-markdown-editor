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
/// Toggle behaviour: tapping a button on already-formatted text removes the formatting.
enum FormattingService {

    // MARK: Bold

    /// Toggle **bold** markers on the selection.
    /// - If selection is already bold (markers included in selection, or markers surround it): remove markers.
    /// - If selection is not bold: wrap in **markers**.
    /// - If no selection: insert **text** placeholder at cursor.
    static func applyBold(to textView: UITextView) {
        let savedRange = textView.selectedRange
        let ns = textView.text as NSString

        textView.undoManager?.beginUndoGrouping()

        if savedRange.length > 0 {
            if let stripRange = boldStripRange(ns, selection: savedRange) {
                // Toggle OFF — remove markers
                let inner = ns.substring(with: stripRange.inner)
                guard let uiRange = textView.uiTextRange(from: stripRange.outer) else {
                    textView.undoManager?.endUndoGrouping(); return
                }
                textView.replace(uiRange, withText: inner)
                textView.selectedRange = NSRange(location: stripRange.outer.location,
                                                length: stripRange.inner.length)
            } else {
                // Toggle ON — wrap
                let selectedText = ns.substring(with: savedRange)
                guard let uiRange = textView.uiTextRange(from: savedRange) else {
                    textView.undoManager?.endUndoGrouping(); return
                }
                textView.replace(uiRange, withText: "**\(selectedText)**")
                textView.selectedRange = NSRange(location: savedRange.location + 2,
                                                length: savedRange.length)
            }
        } else {
            textView.insertText("**text**")
            textView.selectedRange = NSRange(location: savedRange.location + 2, length: 4)
        }

        textView.undoManager?.endUndoGrouping()
        textView.undoManager?.setActionName("Bold")
    }

    // MARK: Italic

    /// Toggle *italic* markers on the selection.
    static func applyItalic(to textView: UITextView) {
        let savedRange = textView.selectedRange
        let ns = textView.text as NSString

        textView.undoManager?.beginUndoGrouping()

        if savedRange.length > 0 {
            if let stripRange = italicStripRange(ns, selection: savedRange) {
                // Toggle OFF — remove markers
                let inner = ns.substring(with: stripRange.inner)
                guard let uiRange = textView.uiTextRange(from: stripRange.outer) else {
                    textView.undoManager?.endUndoGrouping(); return
                }
                textView.replace(uiRange, withText: inner)
                textView.selectedRange = NSRange(location: stripRange.outer.location,
                                                length: stripRange.inner.length)
            } else {
                // Toggle ON — wrap
                let selectedText = ns.substring(with: savedRange)
                guard let uiRange = textView.uiTextRange(from: savedRange) else {
                    textView.undoManager?.endUndoGrouping(); return
                }
                textView.replace(uiRange, withText: "*\(selectedText)*")
                textView.selectedRange = NSRange(location: savedRange.location + 1,
                                                length: savedRange.length)
            }
        } else {
            textView.insertText("*text*")
            textView.selectedRange = NSRange(location: savedRange.location + 1, length: 4)
        }

        textView.undoManager?.endUndoGrouping()
        textView.undoManager?.setActionName("Italic")
    }

    // MARK: Bullet

    /// Toggle bullet prefix on the current line.
    /// If the line already starts with "- ", remove it; otherwise add it.
    static func applyBullet(to textView: UITextView) {
        let savedRange = textView.selectedRange
        let ns = textView.text as NSString

        let lineRange = ns.lineRange(for: savedRange)
        let lineText = ns.substring(with: lineRange)

        textView.undoManager?.beginUndoGrouping()

        guard let uiRange = textView.uiTextRange(from: lineRange) else {
            textView.undoManager?.endUndoGrouping(); return
        }

        if lineText.hasPrefix("- ") {
            // Toggle OFF — remove "- " prefix
            let stripped = String(lineText.dropFirst(2))
            textView.replace(uiRange, withText: stripped)
            // Restore cursor, shifted back by 2 (but not before line start)
            let newLocation = max(lineRange.location, savedRange.location - 2)
            textView.selectedRange = NSRange(location: newLocation, length: 0)
        } else {
            // Toggle ON — add "- " prefix
            textView.replace(uiRange, withText: "- " + lineText)
            textView.selectedRange = NSRange(location: savedRange.location + 2, length: 0)
        }

        textView.undoManager?.endUndoGrouping()
        textView.undoManager?.setActionName("Bullet")
    }

    // MARK: Table

    /// Insert a 3-column × 2-row markdown table at cursor, or replace selection.
    static func insertTable(to textView: UITextView) {
        let savedRange = textView.selectedRange
        let template = "| Header 1 | Header 2 | Header 3 |\n|----------|----------|----------|\n| Cell 1   | Cell 2   | Cell 3   |"

        textView.undoManager?.beginUndoGrouping()

        if savedRange.length > 0 {
            guard let uiRange = textView.uiTextRange(from: savedRange) else {
                textView.undoManager?.endUndoGrouping(); return
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

    // MARK: - Private: toggle detection helpers

    /// Ranges needed to strip bold markers.
    /// `outer` = the full range to replace (includes markers).
    /// `inner` = the range of the text without markers (used as the replacement).
    private struct StripRange {
        let outer: NSRange
        let inner: NSRange
    }

    /// Returns non-nil when the selection is already bold.
    /// Handles two cases:
    ///   1. Selection includes the markers: "**word**" is selected.
    ///   2. Markers surround the selection: "word" is selected inside **word**.
    private static func boldStripRange(_ ns: NSString, selection: NSRange) -> StripRange? {
        let loc = selection.location
        let len = selection.length

        // Case 1: selection itself starts/ends with **
        if len > 4 {
            let sel = ns.substring(with: selection)
            if sel.hasPrefix("**") && sel.hasSuffix("**") {
                let inner = NSRange(location: loc + 2, length: len - 4)
                return StripRange(outer: selection, inner: inner)
            }
        }

        // Case 2: ** surrounds the selection
        let end = loc + len
        guard loc >= 2, end + 2 <= ns.length else { return nil }
        let before = ns.substring(with: NSRange(location: loc - 2, length: 2))
        let after  = ns.substring(with: NSRange(location: end, length: 2))
        guard before == "**" && after == "**" else { return nil }
        let outer = NSRange(location: loc - 2, length: len + 4)
        let inner = NSRange(location: loc, length: len)
        return StripRange(outer: outer, inner: inner)
    }

    /// Returns non-nil when the selection is already italic (single *, not bold **).
    private static func italicStripRange(_ ns: NSString, selection: NSRange) -> StripRange? {
        let loc = selection.location
        let len = selection.length

        // Case 1: selection itself starts/ends with * (but not **)
        if len > 2 {
            let sel = ns.substring(with: selection)
            if sel.hasPrefix("*") && !sel.hasPrefix("**") &&
               sel.hasSuffix("*") && !sel.hasSuffix("**") {
                let inner = NSRange(location: loc + 1, length: len - 2)
                return StripRange(outer: selection, inner: inner)
            }
        }

        // Case 2: single * surrounds the selection (not part of **)
        let end = loc + len
        guard loc >= 1, end + 1 <= ns.length else { return nil }
        let charBefore = ns.substring(with: NSRange(location: loc - 1, length: 1))
        let charAfter  = ns.substring(with: NSRange(location: end, length: 1))
        guard charBefore == "*" && charAfter == "*" else { return nil }

        // Ensure neither * is the inner char of a ** pair
        if loc >= 2, ns.substring(with: NSRange(location: loc - 2, length: 1)) == "*" { return nil }
        if end + 1 < ns.length, ns.substring(with: NSRange(location: end + 1, length: 1)) == "*" { return nil }

        let outer = NSRange(location: loc - 1, length: len + 2)
        let inner = NSRange(location: loc, length: len)
        return StripRange(outer: outer, inner: inner)
    }
}
