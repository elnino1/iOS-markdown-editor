// MarkdownEditor/HighlightingService.swift
import UIKit

struct HighlightingService {

    /// Apply markdown syntax colors to plain text.
    /// Returns NSAttributedString with UIKit attributes — safe to set directly on UITextView.
    /// Pattern priority: headings → bold → italic → code → links.
    static func applyMarkdownColors(
        to text: String,
        baseFont: UIFont = UIFont.preferredFont(forTextStyle: .body).withSize(16)
    ) -> NSAttributedString {
        let result = NSMutableAttributedString(string: text)
        let fullRange = NSRange(location: 0, length: (text as NSString).length)

        // Base attributes: body font + adaptive text color for the entire string.
        // These are applied first so syntax rules can override specific ranges.
        result.addAttributes([
            .font: baseFont,
            .foregroundColor: UIColor.label
        ], range: fullRange)

        // 1. Headings: ^#+ \S
        applyStyle(
            pattern: #"^(#+)\s(.+)$"#,
            options: [.anchorsMatchLines],
            to: result, in: text, fullRange: fullRange,
            attributes: [
                .foregroundColor: ThemeColors.heading,
                .font: UIFont.preferredFont(forTextStyle: .headline)
            ]
        )

        // 2. Bold: **text**
        applyStyle(
            pattern: #"\*\*(.+?)\*\*"#,
            to: result, in: text, fullRange: fullRange,
            attributes: [
                .foregroundColor: ThemeColors.bold,
                .font: UIFont.boldSystemFont(ofSize: baseFont.pointSize)
            ]
        )

        // 3. Italic: *text* (not matching ** bold markers)
        applyStyle(
            pattern: #"(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)"#,
            to: result, in: text, fullRange: fullRange,
            attributes: [
                .foregroundColor: ThemeColors.italic,
                .font: UIFont.italicSystemFont(ofSize: baseFont.pointSize)
            ]
        )

        // 4. Inline code: `text`
        applyStyle(
            pattern: #"`(.+?)`"#,
            to: result, in: text, fullRange: fullRange,
            attributes: [
                .foregroundColor: ThemeColors.code,
                .font: UIFont.monospacedSystemFont(ofSize: baseFont.pointSize, weight: .regular)
            ]
        )

        // 5. Links: [text](url)
        applyStyle(
            pattern: #"\[(.+?)\]\((.+?)\)"#,
            to: result, in: text, fullRange: fullRange,
            attributes: [
                .foregroundColor: ThemeColors.link,
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ]
        )

        return result
    }

    // MARK: - Private

    private static func applyStyle(
        pattern: String,
        options: NSRegularExpression.Options = [],
        to result: NSMutableAttributedString,
        in text: String,
        fullRange: NSRange,
        attributes: [NSAttributedString.Key: Any]
    ) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return }
        regex.matches(in: text, range: fullRange).forEach { match in
            result.addAttributes(attributes, range: match.range)
        }
    }
}
