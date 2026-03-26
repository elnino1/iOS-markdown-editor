// MarkdownEditorTests/MarkdownHighlighterTests.swift
import XCTest
@testable import MarkdownEditor

final class MarkdownHighlighterTests: XCTestCase {

    // EDIT-04: heading line starting with # gets green foreground color
    func testHeadingColoring() throws {
        // Stub: will fail until HighlightingService exists — EXPECTED RED
        XCTFail("Stub — implement HighlightingService in Wave 1")
    }

    // EDIT-04: **bold** text gets blue foreground + bold font
    func testBoldColoring() throws {
        XCTFail("Stub — implement HighlightingService in Wave 1")
    }

    // EDIT-04: *italic* text gets purple foreground + italic font
    func testItalicColoring() throws {
        XCTFail("Stub — implement HighlightingService in Wave 1")
    }

    // EDIT-04: `code` text gets orange foreground + monospaced font
    func testCodeColoring() throws {
        XCTFail("Stub — implement HighlightingService in Wave 1")
    }

    // EDIT-04: [link](url) text gets cyan foreground + underline
    func testLinkColoring() throws {
        XCTFail("Stub — implement HighlightingService in Wave 1")
    }
}
