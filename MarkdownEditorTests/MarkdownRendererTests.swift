// MarkdownEditorTests/MarkdownRendererTests.swift
import XCTest
@testable import MarkdownEditor

final class MarkdownRendererTests: XCTestCase {

    // PREV-02: Headings H1/H2/H3 render with distinct sizes and weights
    func testHeadingsRenderWithVisualHierarchy() {
        let markdown = "# H1\n## H2\n### H3"
        let html = MarkdownRenderer.generateHTML(from: markdown)
        XCTAssertTrue(html.contains("<h1>") || html.contains("<h1 "), "Expected <h1> in output")
        XCTAssertTrue(html.contains("<h2>") || html.contains("<h2 "), "Expected <h2> in output")
        XCTAssertTrue(html.contains("<h3>") || html.contains("<h3 "), "Expected <h3> in output")
    }

    // PREV-03: **bold** and *italic* render as styled text (markers removed)
    func testBoldAndItalicRenderAsStyled() {
        let markdown = "**bold** and *italic*"
        let html = MarkdownRenderer.generateHTML(from: markdown)
        XCTAssertTrue(html.contains("<strong>bold</strong>"), "Expected <strong>bold</strong> in output")
        XCTAssertTrue(html.contains("<em>italic</em>"), "Expected <em>italic</em> in output")
    }

    // PREV-04: Bullet lists and numbered lists render with indentation
    func testListsRenderWithIndentation() {
        let markdown = "- item\n- item2\n\n1. first"
        let html = MarkdownRenderer.generateHTML(from: markdown)
        XCTAssertTrue(html.contains("<ul>") || html.contains("<ul "), "Expected <ul> in output")
        XCTAssertTrue(html.contains("<li>") || html.contains("<li "), "Expected <li> in output")
        XCTAssertTrue(html.contains("<ol>") || html.contains("<ol "), "Expected <ol> in output")
    }

    // PREV-05: Fenced code blocks render with monospace font
    func testCodeBlocksRenderMonospace() {
        let markdown = "```swift\nlet x = 1\n```"
        let html = MarkdownRenderer.generateHTML(from: markdown)
        XCTAssertTrue(html.contains("<pre><code") || html.contains("<pre>\n<code"), "Expected <pre><code in output")
    }

    // PREV-06: Inline code renders with monospace font
    func testInlineCodeRendersMonospace() {
        let markdown = "`code`"
        let html = MarkdownRenderer.generateHTML(from: markdown)
        XCTAssertTrue(html.contains("<code>code</code>"), "Expected <code>code</code> in output")
    }

    // PREV-07: Markdown tables render as visual grid with borders
    func testTablesRenderAsGrid() {
        let markdown = "| A | B |\n|---|---|\n| 1 | 2 |"
        let html = MarkdownRenderer.generateHTML(from: markdown)
        XCTAssertTrue(html.contains("<table>") || html.contains("<table "), "Expected <table> in output")
        XCTAssertTrue(html.contains("<th>") || html.contains("<th "), "Expected <th> in output")
        XCTAssertTrue(html.contains("<td>") || html.contains("<td "), "Expected <td> in output")
    }

    // PREV-09: Rendered HTML includes CSS with prefers-color-scheme for dark mode support
    func testDarkModeCSS() {
        let markdown = "# Dark mode test"
        let html = MarkdownRenderer.generateHTML(from: markdown)
        XCTAssertTrue(html.contains("prefers-color-scheme"), "Expected prefers-color-scheme in HTML output")
    }

    // Initialization check: MarkdownRenderer can be instantiated
    func testMarkdownRendererInitializes() {
        let _ = MarkdownRenderer()
        // If MarkdownRenderer does not exist, this file will not compile
    }
}
