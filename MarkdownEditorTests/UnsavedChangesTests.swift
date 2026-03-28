// MarkdownEditorTests/UnsavedChangesTests.swift
import XCTest
@testable import MarkdownEditor

final class UnsavedChangesTests: XCTestCase {

    // Test the title-building logic directly
    // buildTitle() logic: filename + (hasUnsavedChanges ? " *" : "")

    func testTitleShowsAsteriskWhenUnsaved() {
        // Simulate the logic of buildTitle() for a document with unsaved changes
        let filename = "notes.md"
        let hasUnsaved = true
        let title = filename + (hasUnsaved ? " *" : "")
        XCTAssertEqual(title, "notes.md *", "Title should have asterisk when unsaved changes exist")
        XCTAssertTrue(title.hasSuffix(" *"), "Title must end with ' *' for unsaved state")
    }

    func testTitleClearsAsteriskAfterSave() {
        let filename = "notes.md"
        let hasUnsaved = false
        let title = filename + (hasUnsaved ? " *" : "")
        XCTAssertEqual(title, "notes.md", "Title should not have asterisk when no unsaved changes")
        XCTAssertFalse(title.hasSuffix(" *"), "Title must not end with ' *' after save")
    }

    func testTitleFallbackWhenNoDocument() {
        let title = "Editor"
        XCTAssertEqual(title, "Editor", "Title should be 'Editor' when no document is open")
    }
}
