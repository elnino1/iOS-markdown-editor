// MarkdownEditorTests/MarkdownHighlighterTests.swift
import XCTest
@testable import MarkdownEditor

final class MarkdownHighlighterTests: XCTestCase {

    // EDIT-04: heading line gets a foreground color applied at position 0
    func testHeadingColoring() {
        let result = HighlightingService.applyMarkdownColors(to: "# Hello World")
        let color = result.attribute(.foregroundColor, at: 0, effectiveRange: nil)
        XCTAssertNotNil(color, "Heading line should have .foregroundColor at position 0")
    }

    // EDIT-04: **bold** text gets a foreground color applied
    func testBoldColoring() {
        let result = HighlightingService.applyMarkdownColors(to: "**bold text**")
        let color = result.attribute(.foregroundColor, at: 0, effectiveRange: nil)
        XCTAssertNotNil(color, "**bold** text should have .foregroundColor at position 0")
    }

    // EDIT-04: *italic* text gets a foreground color applied
    func testItalicColoring() {
        let result = HighlightingService.applyMarkdownColors(to: "*italic text*")
        let color = result.attribute(.foregroundColor, at: 0, effectiveRange: nil)
        XCTAssertNotNil(color, "*italic* text should have .foregroundColor at position 0")
    }

    // EDIT-04: `code` text gets a foreground color applied
    func testCodeColoring() {
        let result = HighlightingService.applyMarkdownColors(to: "`code span`")
        let color = result.attribute(.foregroundColor, at: 0, effectiveRange: nil)
        XCTAssertNotNil(color, "`code` span should have .foregroundColor at position 0")
    }

    // EDIT-04: [link](url) text gets a foreground color applied
    func testLinkColoring() {
        let result = HighlightingService.applyMarkdownColors(to: "[link text](https://example.com)")
        let color = result.attribute(.foregroundColor, at: 0, effectiveRange: nil)
        XCTAssertNotNil(color, "[link](url) should have .foregroundColor at position 0")
    }
}
