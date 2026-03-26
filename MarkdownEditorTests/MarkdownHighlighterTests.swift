// MarkdownEditorTests/MarkdownHighlighterTests.swift
import XCTest
@testable import MarkdownEditor

final class MarkdownHighlighterTests: XCTestCase {

    // EDIT-04: heading line starting with # gets a foreground color applied
    func testHeadingColoring() {
        let result = HighlightingService.applyMarkdownColors(to: "# Hello World")
        let hasColoredRun = result.runs.contains { $0.foregroundColor != nil }
        XCTAssertTrue(hasColoredRun, "Heading line should have foreground color applied to at least one run")
    }

    // EDIT-04: **bold** text gets a foreground color applied
    func testBoldColoring() {
        let result = HighlightingService.applyMarkdownColors(to: "**bold text**")
        let hasColoredRun = result.runs.contains { $0.foregroundColor != nil }
        XCTAssertTrue(hasColoredRun, "**bold** text should have foreground color applied")
    }

    // EDIT-04: *italic* text gets a foreground color applied
    func testItalicColoring() {
        let result = HighlightingService.applyMarkdownColors(to: "*italic text*")
        let hasColoredRun = result.runs.contains { $0.foregroundColor != nil }
        XCTAssertTrue(hasColoredRun, "*italic* text should have foreground color applied")
    }

    // EDIT-04: `code` text gets a foreground color applied
    func testCodeColoring() {
        let result = HighlightingService.applyMarkdownColors(to: "`code span`")
        let hasColoredRun = result.runs.contains { $0.foregroundColor != nil }
        XCTAssertTrue(hasColoredRun, "`code` span should have foreground color applied")
    }

    // EDIT-04: [link](url) text gets a foreground color applied
    func testLinkColoring() {
        let result = HighlightingService.applyMarkdownColors(to: "[link text](https://example.com)")
        let hasColoredRun = result.runs.contains { $0.foregroundColor != nil }
        XCTAssertTrue(hasColoredRun, "[link](url) should have foreground color applied")
    }
}
