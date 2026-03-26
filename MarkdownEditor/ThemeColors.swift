// MarkdownEditor/ThemeColors.swift
import UIKit

/// Syntax highlight colors as UIColor dynamic providers.
/// UIColor(dynamicProvider:) adapts automatically to light/dark mode —
/// no @Environment(\.colorScheme) checks needed at call sites.
enum ThemeColors {

    /// Headings (#, ##, ###): green
    static let heading = UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.3, green: 0.8, blue: 0.3, alpha: 1)
            : UIColor(red: 0.0, green: 0.5, blue: 0.0, alpha: 1)
    }

    /// Bold (**text**): blue
    static let bold = UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 1)
            : UIColor(red: 0.1, green: 0.3, blue: 0.8, alpha: 1)
    }

    /// Italic (*text*): purple
    static let italic = UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.8, green: 0.5, blue: 1.0, alpha: 1)
            : UIColor(red: 0.5, green: 0.1, blue: 0.7, alpha: 1)
    }

    /// Inline code (`text`): orange
    static let code = UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1)
            : UIColor(red: 0.8, green: 0.4, blue: 0.0, alpha: 1)
    }

    /// Links ([text](url)): cyan
    static let link = UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0.2, green: 0.9, blue: 0.9, alpha: 1)
            : UIColor(red: 0.0, green: 0.6, blue: 0.7, alpha: 1)
    }
}
