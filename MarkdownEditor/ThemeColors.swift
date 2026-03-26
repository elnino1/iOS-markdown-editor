// MarkdownEditor/ThemeColors.swift
import SwiftUI
import UIKit

extension Color {
    // Each color uses UIColor dynamic provider so it automatically adapts
    // to light/dark mode without manual @Environment(\.colorScheme) checks.

    /// Headings (#, ##, ###): green — distinctive hierarchy marker
    static let markdownHeading = Color(
        uiColor: UIColor { tc in
            tc.userInterfaceStyle == .dark
                ? UIColor(red: 0.3, green: 0.8, blue: 0.3, alpha: 1)   // lighter green in dark
                : UIColor(red: 0, green: 0.5, blue: 0, alpha: 1)        // darker green in light
        }
    )

    /// Bold (**text**): blue
    static let markdownBold = Color(
        uiColor: UIColor { tc in
            tc.userInterfaceStyle == .dark
                ? UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1)   // lighter blue in dark
                : UIColor(red: 0.1, green: 0.3, blue: 0.8, alpha: 1)    // darker blue in light
        }
    )

    /// Italic (*text*): purple
    static let markdownItalic = Color(
        uiColor: UIColor { tc in
            tc.userInterfaceStyle == .dark
                ? UIColor(red: 0.8, green: 0.5, blue: 1.0, alpha: 1)   // lighter purple in dark
                : UIColor(red: 0.5, green: 0.1, blue: 0.7, alpha: 1)    // darker purple in light
        }
    )

    /// Inline code (`text`): orange
    static let markdownCode = Color(
        uiColor: UIColor { tc in
            tc.userInterfaceStyle == .dark
                ? UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1)   // lighter orange in dark
                : UIColor(red: 0.8, green: 0.4, blue: 0.0, alpha: 1)    // darker orange in light
        }
    )

    /// Links ([text](url)): cyan
    static let markdownLink = Color(
        uiColor: UIColor { tc in
            tc.userInterfaceStyle == .dark
                ? UIColor(red: 0.2, green: 0.9, blue: 0.9, alpha: 1)   // lighter cyan in dark
                : UIColor(red: 0.0, green: 0.6, blue: 0.7, alpha: 1)    // darker cyan in light
        }
    )
}
