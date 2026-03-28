// MarkdownEditor/PreviewView.swift
import SwiftUI
import WebKit
import SafariServices

/// SwiftUI wrapper for WKWebView that renders markdown as formatted HTML.
/// - Accepts a markdown string as input.
/// - Calls MarkdownRenderer.generateHTML(from:) to produce the HTML document.
/// - WKWebView handles light/dark mode automatically via CSS prefers-color-scheme
///   embedded in the HTML output — no UIView.overrideUserInterfaceStyle needed.
/// - Link taps are intercepted via WKNavigationDelegate and opened in SFSafariViewController.
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
            // HTML document fully loaded — WKWebView is ready for interaction.
        }

        /// Intercepts navigation actions.
        /// Link taps (http/https) are cancelled and opened in SFSafariViewController.
        /// All other navigations (initial page load, fragment jumps) are allowed.
        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            if navigationAction.navigationType == .linkActivated,
               let url = navigationAction.request.url,
               url.scheme == "http" || url.scheme == "https" {
                // Prevent default (would open Safari app or navigate WKWebView)
                decisionHandler(.cancel)

                // Present SFSafariViewController in-app
                let safariVC = SFSafariViewController(url: url)
                safariVC.modalPresentationStyle = .pageSheet

                // Find the topmost presented view controller to present from
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }),
                   let rootVC = keyWindow.rootViewController {
                    var topVC = rootVC
                    while let presented = topVC.presentedViewController {
                        topVC = presented
                    }
                    topVC.present(safariVC, animated: true)
                }
            } else {
                // Allow initial page load and all non-link navigations
                decisionHandler(.allow)
            }
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
