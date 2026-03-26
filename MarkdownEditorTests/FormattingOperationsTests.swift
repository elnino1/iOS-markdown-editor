// MarkdownEditorTests/FormattingOperationsTests.swift
import XCTest
@testable import MarkdownEditor

final class FormattingOperationsTests: XCTestCase {

    // FMT-01: Bold wraps selected text in **markers**
    func testBoldWrapsSelectedText() {
        XCTFail("Not yet implemented")
    }

    // FMT-01: Bold inserts **text** placeholder when nothing selected
    func testBoldInsertsAtCursor() {
        XCTFail("Not yet implemented")
    }

    // FMT-01: Bold with emoji does not corrupt UTF-16 boundaries
    func testBoldWrapsSelectedText_WithEmoji() {
        XCTFail("Not yet implemented")
    }

    // FMT-02: Italic wraps selected text in *markers*
    func testItalicWrapsSelectedText() {
        XCTFail("Not yet implemented")
    }

    // FMT-02: Italic inserts *text* placeholder when nothing selected
    func testItalicInsertsAtCursor() {
        XCTFail("Not yet implemented")
    }

    // FMT-03: Bullet prefixes current line with "- "
    func testBulletPrefixesLine() {
        XCTFail("Not yet implemented")
    }

    // FMT-03: Bullet uses NSString.lineRange (handles CRLF line endings)
    func testBulletPrefixesLine_CRLF() {
        XCTFail("Not yet implemented")
    }

    // FMT-04: Table inserts 3-column x 2-row template at cursor
    func testTableInsertsTemplate() {
        XCTFail("Not yet implemented")
    }

    // FMT-04: Table replaces selected text
    func testTableReplacesSelection() {
        XCTFail("Not yet implemented")
    }
}
