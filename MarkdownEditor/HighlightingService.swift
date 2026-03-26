// MarkdownEditor/HighlightingService.swift
import Foundation
import SwiftUI

struct HighlightingService {

    /// Apply markdown syntax colors to plain text.
    /// Returns AttributedString with colors applied to matched ranges.
    /// Keeps MarkdownDocument.text as String (no serialization concern).
    ///
    /// Pattern application order: headings → bold → italic → code → links
    /// (headings first so ## text is colored before bold/italic could interfere)
    static func applyMarkdownColors(to text: String) -> AttributedString {
        var result = AttributedString(text)
        let nsText = text as NSString
        let fullRange = NSRange(location: 0, length: nsText.length)

        // 1. Headings: ^#+\s.+$ (anchors to line start)
        let headingRanges = matchRanges(#"^(#+)\s(.+)$"#, options: [.anchorsMatchLines], in: text, fullRange: fullRange, result: result)
        for range in headingRanges {
            result[range].foregroundColor = .markdownHeading
            result[range].font = .headline
        }

        // 2. Bold: **text** (non-greedy)
        let boldRanges = matchRanges(#"\*\*(.+?)\*\*"#, in: text, fullRange: fullRange, result: result)
        for range in boldRanges {
            result[range].foregroundColor = .markdownBold
            result[range].font = .body.bold()
        }

        // 3. Italic: *text* (non-greedy, must not match ** bold markers)
        // Pattern uses negative lookbehind/lookahead to avoid matching ** bold markers
        let italicRanges = matchRanges(#"(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)"#, in: text, fullRange: fullRange, result: result)
        for range in italicRanges {
            result[range].foregroundColor = .markdownItalic
            result[range].font = .body.italic()
        }

        // 4. Inline code: `text`
        let codeRanges = matchRanges(#"`(.+?)`"#, in: text, fullRange: fullRange, result: result)
        for range in codeRanges {
            result[range].foregroundColor = .markdownCode
            result[range].font = .body.monospaced()
        }

        // 5. Links: [text](url)
        let linkRanges = matchRanges(#"\[(.+?)\]\((.+?)\)"#, in: text, fullRange: fullRange, result: result)
        for range in linkRanges {
            result[range].foregroundColor = .markdownLink
            result[range].underlineStyle = .single
        }

        return result
    }

    // MARK: - Private helper

    private static func matchRanges(
        _ pattern: String,
        options: NSRegularExpression.Options = [],
        in text: String,
        fullRange: NSRange,
        result: AttributedString
    ) -> [Range<AttributedString.Index>] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return [] }
        let matches = regex.matches(in: text, range: fullRange)
        return matches.compactMap { match -> Range<AttributedString.Index>? in
            guard let range = Range(match.range, in: text),
                  let attrRange = Range(range, in: result) else { return nil }
            return attrRange
        }
    }
}
