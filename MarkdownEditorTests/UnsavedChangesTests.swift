// MarkdownEditorTests/UnsavedChangesTests.swift
import XCTest
@testable import MarkdownEditor

final class UnsavedChangesTests: XCTestCase {

    // EDIT-03: buildTitle() appends " *" when document.hasUnsavedChanges == true
    func testTitleShowsAsteriskWhenUnsaved() throws {
        // Stub: EditorView.buildTitle() doesn't exist yet — EXPECTED RED
        XCTFail("Stub — implement EditorView.buildTitle() in Wave 2")
    }

    // EDIT-03: buildTitle() returns plain filename when document.hasUnsavedChanges == false
    func testTitleClearsAsteriskAfterSave() throws {
        XCTFail("Stub — implement EditorView.buildTitle() in Wave 2")
    }
}
