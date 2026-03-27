// MarkdownEditor/PreviewView.swift
import SwiftUI
import WebKit

/// SwiftUI wrapper for WKWebView that renders markdown as formatted HTML.
/// - Accepts a markdown string as input.
/// - Calls MarkdownRenderer.generateHTML(from:) to produce the HTML document.
/// - WKWebView handles light/dark mode automatically via CSS prefers-color-scheme
///   embedded in the HTML output — no UIView.overrideUserInterfaceStyle needed.
/// - Phase 6 will add toggle wiring and SFSafariViewController link handling.
struct PreviewView: UIViewRepresentable {

    /// The raw markdown string to render. Changes trigger a webView reload via updateUIView.
    let markdownString: String

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        // Allow inline media without user gesture (future: embedded images)
        config.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        // Transparent background so the SwiftUI container background shows through
        // before the HTML document background-color loads.
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let html = MarkdownRenderer.generateHTML(from: markdownString)
        // baseURL = Bundle.main.bundleURL so relative references in HTML can resolve
        webView.loadHTMLString(html, baseURL: Bundle.main.bundleURL)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, WKNavigationDelegate {

        /// Called when the HTML document has fully loaded and rendered.
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Phase 6: post-load JS execution goes here if needed.
        }

        /// Intercepts navigation actions.
        /// Phase 5: allows all navigations (no link interception yet).
        /// Phase 6: will cancel link taps and present SFSafariViewController.
        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            // Phase 5: allow all navigations through
            // Phase 6 will check: navigationAction.navigationType == .linkActivated
            //   and present SFSafariViewController for http/https URLs
            decisionHandler(.allow)
        }
    }
}

// MARK: - Preview

#Preview {
    let sampleMarkdown = """
    # Hello, Markdown!

    This is a **bold** statement and *italic* text.

    ## Lists

    - Apple
    - Banana
    - Cherry

    1. First item
    2. Second item

    ## Code

    Inline `code` looks like this.

    ```swift
    let greeting = "Hello, World!"
    print(greeting)
    ```

    ## Table

    | Name  | Score |
    |-------|-------|
    | Alice | 95    |
    | Bob   | 87    |

    [Tap me](https://apple.com)
    """

    PreviewView(markdownString: sampleMarkdown)
        .ignoresSafeArea()
}
