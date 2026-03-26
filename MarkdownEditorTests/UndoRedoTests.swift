// MarkdownEditorTests/UndoRedoTests.swift
import XCTest
@testable import MarkdownEditor

final class UndoRedoTests: XCTestCase {

    // UNDO-01: Undo reverts last toolbar formatting action
    func testUndoRevertsFormatting() {
        XCTFail("Not yet implemented")
    }

    // UNDO-01: Undo button is disabled when stack is empty
    func testUndoDisabledWhenStackEmpty() {
        XCTFail("Not yet implemented")
    }

    // UNDO-01: Bold wrapping is one atomic undo step (not two separate undos for two markers)
    func testBoldIsAtomicUndo() {
        XCTFail("Not yet implemented")
    }

    // UNDO-02: Redo re-applies formatting after undo
    func testRedoReappliesFormatting() {
        XCTFail("Not yet implemented")
    }

    // UNDO-02: Redo button is disabled when redo stack is empty
    func testRedoDisabledWhenRedoStackEmpty() {
        XCTFail("Not yet implemented")
    }
}
