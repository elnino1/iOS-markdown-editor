// MarkdownEditorTests/UndoRedoTests.swift
import XCTest
@testable import MarkdownEditor

final class UndoRedoTests: XCTestCase {

    // UNDO-01: Undo reverts last toolbar formatting action
    func testUndoRevertsFormatting() {
        let tv = UITextView()
        tv.text = "hello"
        tv.selectedRange = NSRange(location: 5, length: 0)
        FormattingService.applyBold(to: tv)
        XCTAssertEqual(tv.text, "hello**text**", "Bold should have inserted placeholder")
        tv.undoManager?.undo()
        XCTAssertEqual(tv.text, "hello", "Undo should revert bold insertion")
    }

    // UNDO-01: Undo button is disabled when stack is empty
    func testUndoDisabledWhenStackEmpty() {
        let tv = UITextView()
        tv.text = "fresh"
        // No modifications — undo stack is empty
        XCTAssertFalse(tv.undoManager?.canUndo ?? true,
                       "canUndo should be false on a fresh UITextView with no edits")
    }

    // UNDO-01: Bold wrapping is one atomic undo step (not two separate undos for two markers)
    func testBoldIsAtomicUndo() {
        let tv = UITextView()
        tv.text = "hello world"
        tv.selectedRange = NSRange(location: 0, length: 5)
        FormattingService.applyBold(to: tv)
        XCTAssertEqual(tv.text, "**hello** world", "Bold should wrap selected text")
        // Undo exactly once — should revert completely, not partially
        tv.undoManager?.undo()
        XCTAssertEqual(tv.text, "hello world",
                       "One undo should fully revert bold wrapping (atomic group)")
    }

    // UNDO-02: Redo re-applies formatting after undo
    func testRedoReappliesFormatting() {
        let tv = UITextView()
        tv.text = "hello"
        tv.selectedRange = NSRange(location: 5, length: 0)
        FormattingService.applyBold(to: tv)
        XCTAssertEqual(tv.text, "hello**text**")
        tv.undoManager?.undo()
        XCTAssertEqual(tv.text, "hello", "Undo should revert")
        tv.undoManager?.redo()
        XCTAssertEqual(tv.text, "hello**text**", "Redo should re-apply bold insertion")
    }

    // UNDO-02: Redo button is disabled when redo stack is empty
    func testRedoDisabledWhenRedoStackEmpty() {
        let tv = UITextView()
        tv.text = "fresh"
        // No undo history — redo stack is empty
        XCTAssertFalse(tv.undoManager?.canRedo ?? true,
                       "canRedo should be false when no undo has been performed")
    }
}
