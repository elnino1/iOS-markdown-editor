// MarkdownEditor/MarkdownRenderer.swift
import Foundation
import JavaScriptCore

final class MarkdownRenderer {

    // MARK: - Bundle helper

    /// Returns the bundle that contains MarkdownRenderer.swift (works in both app and unit-test contexts).
    private static let resourceBundle: Bundle = Bundle(for: MarkdownRenderer.self)

    // MARK: - Singleton JS context (created once, reused)

    private static let jsContext: JSContext? = {
        guard let context = JSContext() else { return nil }

        // JSContext has no window/document — provide minimal shims so UMD bundles work
        context.evaluateScript("""
            var window = this;
            var self = this;
            var globalThis = this;
            var module = { exports: {} };
            var exports = module.exports;
        """)

        // Load markdown-it.min.js from bundle
        if let url = resourceBundle.url(forResource: "markdown-it.min", withExtension: "js"),
           let script = try? String(contentsOf: url, encoding: .utf8) {
            context.evaluateScript(script)
        }

        // After evaluating UMD bundle, markdownit may be on module.exports or on global
        context.evaluateScript("""
            var markdownitLib = (typeof markdownit !== 'undefined') ? markdownit :
                                (module && module.exports && typeof module.exports === 'function') ? module.exports :
                                null;
            // Reset module for next UMD bundle
            module = { exports: {} };
            exports = module.exports;
        """)

        // Load markdown-it-table plugin from bundle
        if let tableUrl = resourceBundle.url(forResource: "markdown-it-table.min", withExtension: "js"),
           let tableScript = try? String(contentsOf: tableUrl, encoding: .utf8) {
            context.evaluateScript(tableScript)
        }

        // Grab the table plugin (UMD export)
        context.evaluateScript("""
            var markdownItTablePlugin = (typeof markdownItMultimdTable !== 'undefined') ? markdownItMultimdTable :
                                        (module && module.exports && typeof module.exports === 'function') ? module.exports :
                                        null;
        """)

        // Initialize markdown-it and register table plugin
        context.evaluateScript("""
            var md = null;
            if (markdownitLib) {
                md = markdownitLib({ html: false, linkify: false, typographer: false });
                if (markdownItTablePlugin) {
                    md.use(markdownItTablePlugin);
                }
            }

            function renderToHTML(markdownText) {
                if (!md) return '<p>Error: markdown-it not loaded</p>';
                return md.render(markdownText);
            }
        """)

        return context
    }()

    // MARK: - CSS content (read from bundle once)

    private static let cssContent: String = {
        guard let url = resourceBundle.url(forResource: "markdown-preview", withExtension: "css"),
              let css = try? String(contentsOf: url, encoding: .utf8) else {
            return "/* markdown-preview.css not found */"
        }
        return css
    }()

    // MARK: - Public API

    /// Generates a complete HTML document string from a markdown input.
    /// The returned string is ready to pass to WKWebView.loadHTMLString(_:baseURL:).
    /// Uses JavaScriptCore to run markdown-it synchronously for immediate HTML output.
    static func generateHTML(from markdown: String) -> String {
        // Render markdown → HTML fragment using JavaScriptCore
        let bodyHTML: String
        if let context = jsContext,
           let result = context.evaluateScript("renderToHTML(\(markdown.jsonEncoded()))"),
           !result.isUndefined, !result.isNull {
            bodyHTML = result.toString() ?? ""
        } else {
            bodyHTML = "<p>\(markdown.escapingHTMLEntities())</p>"
        }

        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
            \(cssContent)
            </style>
        </head>
        <body>
            <div id="content">\(bodyHTML)</div>
        </body>
        </html>
        """
    }
}

// MARK: - String helpers

private extension String {
    /// Encodes a Swift String as a JavaScript string literal (JSON-encoded).
    /// Wraps in an array so JSONSerialization accepts it as a top-level value,
    /// then strips the surrounding "[" and "]" to get the quoted string literal.
    func jsonEncoded() -> String {
        let data = try? JSONSerialization.data(withJSONObject: [self])
        guard let bytes = data, let json = String(data: bytes, encoding: .utf8) else {
            return "\"\""
        }
        // json is ["...escaped..."] — strip the outer [ and ]
        let trimmed = json.dropFirst().dropLast()
        return String(trimmed)
    }

    /// Escapes HTML entities for safe inline insertion.
    func escapingHTMLEntities() -> String {
        self
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
