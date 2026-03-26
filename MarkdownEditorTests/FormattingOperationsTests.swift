// MarkdownEditorTests/FormattingOperationsTests.swift
import XCTest
@testable import MarkdownEditor

final class FormattingOperationsTests: XCTestCase {

    // FMT-01: Bold wraps selected text in **markers**
    func testBoldWrapsSelectedText() {
        let tv = UITextView()
        tv.text = "hello world"
        tv.selectedRange = NSRange(location: 0, length: 5)
        FormattingService.applyBold(to: tv)
        XCTAssertEqual(tv.text, "**hello** world")
        XCTAssertEqual(tv.selectedRange, NSRange(location: 2, length: 5))
    }

    // FMT-01: Bold inserts **text** placeholder when nothing selected
    func testBoldInsertsAtCursor() {
        let tv = UITextView()
        tv.text = "hello"
        tv.selectedRange = NSRange(location: 5, length: 0)
        FormattingService.applyBold(to: tv)
        XCTAssertEqual(tv.text, "hello**text**")
        XCTAssertEqual(tv.selectedRange, NSRange(location: 7, length: 4))
    }

    // FMT-01: Bold with emoji does not corrupt UTF-16 boundaries
    func testBoldWrapsSelectedText_WithEmoji() {
        // "Hi 👨‍👩‍👧 there" — the emoji is a multi-codepoint sequence
        let fullString = "Hi \u{1F468}\u{200D}\u{1F469}\u{200D}\u{1F467} there"
        let tv = UITextView()
        tv.text = fullString
        // Find UTF-16 location of "there" using NSString
        let ns = fullString as NSString
        let thereRange = ns.range(of: "there")
        tv.selectedRange = thereRange
        FormattingService.applyBold(to: tv)
        let expected = "Hi \u{1F468}\u{200D}\u{1F469}\u{200D}\u{1F467} **there**"
        XCTAssertEqual(tv.text, expected)
        // Emoji should be unchanged
        XCTAssertTrue(tv.text.hasPrefix("Hi \u{1F468}\u{200D}\u{1F469}\u{200D}\u{1F467} "))
    }

    // FMT-02: Italic wraps selected text in *markers*
    func testItalicWrapsSelectedText() {
        let tv = UITextView()
        tv.text = "hello world"
        tv.selectedRange = NSRange(location: 0, length: 5)
        FormattingService.applyItalic(to: tv)
        XCTAssertEqual(tv.text, "*hello* world")
        XCTAssertEqual(tv.selectedRange, NSRange(location: 1, length: 5))
    }

    // FMT-02: Italic inserts *text* placeholder when nothing selected
    func testItalicInsertsAtCursor() {
        let tv = UITextView()
        tv.text = "hello"
        tv.selectedRange = NSRange(location: 5, length: 0)
        FormattingService.applyItalic(to: tv)
        XCTAssertEqual(tv.text, "hello*text*")
        XCTAssertEqual(tv.selectedRange, NSRange(location: 6, length: 4))
    }

    // FMT-03: Bullet prefixes current line with "- "
    func testBulletPrefixesLine() {
        let tv = UITextView()
        tv.text = "This is a line"
        tv.selectedRange = NSRange(location: 4, length: 0)
        FormattingService.applyBullet(to: tv)
        XCTAssertEqual(tv.text, "- This is a line")
        XCTAssertEqual(tv.selectedRange, NSRange(location: 6, length: 0))
    }

    // FMT-03: Bullet uses NSString.lineRange (handles CRLF line endings)
    func testBulletPrefixesLine_CRLF() {
        let tv = UITextView()
        tv.text = "line one\r\nline two"
        // cursor in "line one"
        tv.selectedRange = NSRange(location: 3, length: 0)
        FormattingService.applyBullet(to: tv)
        // "line one\r\n" becomes "- line one\r\n", no double newline
        XCTAssertTrue(tv.text.hasPrefix("- line one\r\n"))
        XCTAssertTrue(tv.text.hasSuffix("line two"))
        // No extra newline injected
        XCTAssertFalse(tv.text.contains("\r\n\r\n"))
        XCTAssertFalse(tv.text.contains("\n\n"))
    }

    // FMT-04: Table inserts 3-column x 2-row template at cursor
    func testTableInsertsTemplate() {
        let tv = UITextView()
        tv.text = "before"
        tv.selectedRange = NSRange(location: 6, length: 0)
        FormattingService.insertTable(to: tv)
        let expected = "before| Header 1 | Header 2 | Header 3 |\n|----------|----------|----------|\n| Cell 1   | Cell 2   | Cell 3   |"
        XCTAssertTrue(tv.text.hasPrefix(expected),
                      "Expected text to start with table template but got: \(tv.text)")
    }

    // FMT-04: Table replaces selected text
    func testTableReplacesSelection() {
        let tv = UITextView()
        tv.text = "replace me"
        tv.selectedRange = NSRange(location: 0, length: 10)
        FormattingService.insertTable(to: tv)
        let tableStart = "| Header 1 | Header 2 | Header 3 |"
        XCTAssertTrue(tv.text.hasPrefix(tableStart),
                      "Expected text to start with table header but got: \(tv.text)")
        XCTAssertFalse(tv.text.contains("replace me"),
                       "Selected text should have been replaced")
    }
}
