# Phase 5: Preview Infrastructure - Research

**Researched:** 2026-03-27
**Domain:** WKWebView-based markdown rendering for iOS
**Confidence:** HIGH

## Summary

Phase 5 requires building a self-contained markdown renderer that displays headings, bold/italic, lists, code blocks, inline code, tables, and respects light/dark mode—all without network access. The standard approach is **WKWebView + markdown-it (JavaScript parser) + highlight.js (syntax highlighting)**, with CSS injected for dark mode support via `prefers-color-scheme` media queries.

**Primary recommendation:** Bundle markdown-it and highlight.js as static files in the app bundle, inject them into WKWebView alongside a stylesheet with prefers-color-scheme support. Use WKNavigationDelegate to intercept link clicks and open them via SFSafariViewController.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| WKWebView | iOS native (WebKit) | HTML rendering engine | Apple's modern web view; full markdown HTML fidelity; dark mode support via CSS media queries |
| markdown-it | v14.1.1 (JavaScript) | Markdown → HTML parser | CommonMark-compliant; supports tables via plugin; minimal dependencies; bundled offline; widely used in electron apps |
| highlight.js | v11.9.0+ (JavaScript) | Code block syntax highlighting | Industry standard for syntax highlighting; supports 200+ languages; zero-dependency |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| SFSafariViewController | iOS native | In-app link browsing | Opens URLs intercepted from WKWebView; shares Safari features (Reader, AutoFill); standard iOS pattern |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| WKWebView + markdown-it | SwiftUI native MarkdownUI | Native components (no HTML/CSS), but table/code rendering less flexible; no highlight.js integration |
| markdown-it | marked.js | Both CommonMark parsers; marked is faster for large docs, markdown-it has better plugin ecosystem for tables |
| highlight.js | Prism.js | Similar feature set; highlight.js simpler to bundle as single file; Prism more modular |

**Installation:**
```bash
# No Swift package import needed — markdown-it and highlight.js are bundled as static JS files
# Download from:
# - https://cdn.jsdelivr.net/npm/markdown-it@14.1.1/dist/markdown-it.min.js
# - https://cdn.jsdelivr.net/npm/highlight.js@11.9.0/dist/highlight.min.js
# Add to Xcode: drag files into project, ensure "Copy Bundle Resources" is checked
```

**Version verification:** markdown-it v14.1.1 (stable as of Feb 2025), highlight.js v11.9.0+ confirmed current. Both are vendored as static assets, so Xcode build includes them directly.

---

## Architecture Patterns

### Recommended Project Structure
```
MarkdownEditor/
├── PreviewView.swift          # WKWebView wrapper component
├── MarkdownRenderer.swift     # Orchestrates markdown → HTML pipeline
├── MarkdownRendererTests.swift # XCTest for rendering accuracy

Resources/
├── markdown-it.min.js         # Parser (bundled)
├── highlight.min.js           # Syntax highlighting (bundled)
├── markdown-preview.css       # Styles with prefers-color-scheme
├── markdown-preview.js        # Helper JS: init parser, setup handlers
```

### Pattern 1: WKWebView Initialization with Bundled JavaScript

**What:** Create a configured WKWebView instance that injects markdown-it and highlight.js at document start, then loads markdown HTML.

**When to use:** Every time the preview is displayed; avoids recreating the parser for each render.

**Example:**
```swift
// Source: Apple WKWebView Documentation
import WebKit

class MarkdownRenderer {
    let webView = WKWebView()

    func setupWebView() {
        let config = WKWebViewConfiguration()
        let userContent = WKUserContentController()

        // Inject markdown-it library
        if let mdPath = Bundle.main.url(forResource: "markdown-it.min", withExtension: "js"),
           let mdScript = try? String(contentsOf: mdPath) {
            let mdUserScript = WKUserScript(
                source: mdScript,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: true
            )
            userContent.addUserScript(mdUserScript)
        }

        // Inject highlight.js library
        if let hlPath = Bundle.main.url(forResource: "highlight.min", withExtension: "js"),
           let hlScript = try? String(contentsOf: hlPath) {
            let hlUserScript = WKUserScript(
                source: hlScript,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: true
            )
            userContent.addUserScript(hlUserScript)
        }

        config.userContentController = userContent
        webView = WKWebView(frame: .zero, configuration: config)
    }

    func renderMarkdown(_ md: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <link rel="stylesheet" href="markdown-preview.css">
        </head>
        <body>
            <div id="content"></div>
            <script src="markdown-preview.js"></script>
            <script>
                window.renderMarkdown(\(markdownToJSON(md)))
            </script>
        </body>
        </html>
        """

        webView.loadHTMLString(html, baseURL: Bundle.main.bundleURL)
        // Wait for didFinish delegate before resolving completion
    }
}
```

### Pattern 2: Dark Mode via CSS prefers-color-scheme

**What:** Single CSS file that automatically adapts colors based on system appearance setting using `@media (prefers-color-scheme: dark)`.

**When to use:** Always—no imperative dark mode switching needed; system appearance changes automatically update rendered output.

**Example:**
```css
/* Source: Apple WWDC 2019 "Supporting Dark Mode in Web Content" */
:root {
    color-scheme: light dark;
    --text-primary: #000;
    --text-secondary: #666;
    --background: #fff;
    --code-bg: #f5f5f5;
    --border: #ddd;
}

@media (prefers-color-scheme: dark) {
    :root {
        --text-primary: #fff;
        --text-secondary: #ccc;
        --background: #1a1a1a;
        --code-bg: #2a2a2a;
        --border: #444;
    }
}

body {
    color: var(--text-primary);
    background-color: var(--background);
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
    line-height: 1.6;
    margin: 16px;
}

h1, h2, h3 { font-weight: 600; margin-top: 24px; margin-bottom: 12px; }
h1 { font-size: 2em; }
h2 { font-size: 1.5em; }
h3 { font-size: 1.25em; }

strong { font-weight: 700; }
em { font-style: italic; }

code, pre {
    background-color: var(--code-bg);
    border: 1px solid var(--border);
    border-radius: 4px;
    font-family: 'Menlo', monospace;
}

code { padding: 2px 6px; font-size: 0.9em; }
pre {
    padding: 12px;
    overflow-x: auto;
    margin: 12px 0;
}

table {
    border-collapse: collapse;
    width: 100%;
    margin: 12px 0;
}

th, td {
    border: 1px solid var(--border);
    padding: 8px;
    text-align: left;
}

th { background-color: var(--code-bg); font-weight: 600; }
```

### Pattern 3: Link Interception via WKNavigationDelegate

**What:** Implement `decidePolicyFor navigationAction` to intercept link clicks and open them in SFSafariViewController instead of the default Safari app.

**When to use:** Every WKWebView that displays user-clickable content (links in rendered markdown).

**Example:**
```swift
// Source: Apple WKNavigationDelegate Documentation
import SafariServices

extension MarkdownRenderer: WKNavigationDelegate {
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        if navigationAction.navigationType == .linkActivated,
           let url = navigationAction.request.url {
            // Prevent default navigation (would open Safari app)
            decisionHandler(.cancel)

            // Open in SFSafariViewController instead
            let safari = SFSafariViewController(url: url)
            presentingViewController?.present(safari, animated: true)
        } else {
            // Allow other navigations (document load, form submit, etc.)
            decisionHandler(.allow)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // Called when HTML has fully loaded — safe to execute JS or resolve completion handlers
    }
}
```

### Anti-Patterns to Avoid

- **Not waiting for WKWebView delegate before calling JS:** `loadHTMLString` returns immediately but loading is async. Calling `evaluateJavaScript` before `didFinish` may fail silently. Always wait for the delegate.
- **Hardcoding colors in CSS:** System dark mode changes won't work. Always use CSS variables and `prefers-color-scheme` media queries.
- **Not verifying Bundle.main.url for bundled files:** Files must be in "Copy Bundle Resources" build phase, not just added to project. Always verify with `Bundle.main.url(forResource:withExtension:)`.
- **Using .allow for all navigations:** Opening links in the app-wide Safari (missing SFSafariViewController) breaks user flow. Explicitly `.cancel` link clicks and handle manually.
- **Forgetting to set WKNavigationDelegate:** Without it, link clicks default to external Safari. Must implement `decidePolicyFor navigationAction`.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Markdown HTML conversion | Custom regex parser | markdown-it library | Regex breaks on nested structures, edge cases, GFM tables; markdown-it is CommonMark-compliant and battle-tested |
| Syntax highlighting for code blocks | Manual HTML span coloring | highlight.js | Custom requires language grammar files for 200+ languages; highlight.js handles all at once with minimal bundle size |
| Dark mode in web content | UIView.overrideUserInterfaceStyle + manual color swaps | CSS prefers-color-scheme media query | UIKit overrides insufficient for HTML/CSS content; media queries automatically adapt without code changes |
| Link handling from web views | Default Safari navigation | WKNavigationDelegate + SFSafariViewController | Default breaks in-app UX; delegate + SFSafariViewController is the iOS standard pattern for browsing within an app |
| Cross-platform markdown tables | HTML table generation | markdown-it with table plugin | Tables are HTML-only in CommonMark spec; markdown-it plugin handles GFM table syntax (pipes and dashes) |

**Key insight:** Markdown rendering is deceptively complex due to nested structures, special characters, edge cases, and numerous flavors (CommonMark, GFM, tables). Mature libraries handle these; custom parsing fails on real-world input.

---

## Common Pitfalls

### Pitfall 1: WKWebView Loading Timing — Async Execution

**What goes wrong:** You call `loadHTMLString` and immediately try to execute JavaScript or access the DOM. The JS runs against an incomplete or empty document, producing no output or silent failures.

**Why it happens:** `loadHTMLString` returns immediately but parsing and rendering happen asynchronously on the main thread. JavaScript injection at document start happens before content arrives.

**How to avoid:**
- Always implement `WKNavigationDelegate.webView(_:didFinish:)` and call completion handlers or JS execution *only after* this callback fires.
- If you need to execute JS after HTML load, do it in `didFinish`, not immediately after `loadHTMLString`.

**Warning signs:**
- Rendered markdown appears blank or unstyled despite correct HTML.
- JavaScript console shows "undefined" when accessing DOM elements.
- Event handlers or JS functions don't fire.

### Pitfall 2: Dark Mode in WKWebView Not Working with UIView.overrideUserInterfaceStyle

**What goes wrong:** You set `webView.overrideUserInterfaceStyle = .dark` but the HTML/CSS rendered inside still shows light colors, as if the override had no effect.

**Why it happens:** `overrideUserInterfaceStyle` only affects UIKit components, not web content. HTML pages rely on their own CSS and the `prefers-color-scheme` media query, which is determined by the system setting, not UIView overrides.

**How to avoid:**
- Do NOT rely on `overrideUserInterfaceStyle` for web content dark mode.
- Always provide a CSS file with `color-scheme: light dark` in `:root` and `@media (prefers-color-scheme: dark)` blocks for dark mode colors.
- Inject this CSS into every WKWebView instance via WKUserScript or `<link>` tag in the HTML.

**Warning signs:**
- Dark mode works for SwiftUI views but not the preview (WKWebView portion).
- CSS dark mode rules are written but don't apply.
- Manual testing shows light background with dark text in dark mode.

### Pitfall 3: Link Clicks Open External Safari Instead of SFSafariViewController

**What goes wrong:** User taps a markdown link in the preview, and it opens the Safari app (full context switch, loss of focus on the editor).

**Why it happens:** WKWebView's default `decidePolicyFor navigationAction` behavior is `.allow`, which navigates the link in-app by default. For external links, this still falls through to Safari. You must explicitly intercept and handle it.

**How to avoid:**
- Implement `WKNavigationDelegate` on your WKWebView.
- In `decidePolicyFor navigationAction`, check `navigationType == .linkActivated` and `url` scheme.
- Return `.cancel` to prevent default behavior, then manually present `SFSafariViewController(url:)`.

**Warning signs:**
- Tapping links switches to Safari app.
- No WKNavigationDelegate set on webView.
- `decidePolicyFor navigationAction` not implemented.

### Pitfall 4: Bundled JavaScript Files Not Found at Runtime

**What goes wrong:** App crashes or WKUserScript injection fails silently because `Bundle.main.url(forResource:withExtension:)` returns nil for markdown-it.min.js.

**Why it happens:** File was added to the Xcode project but not included in "Copy Bundle Resources" build phase. Or the filename doesn't match (e.g., "markdown-it.min.js" vs. "markdown-it.js").

**How to avoid:**
- After dragging a JS file into Xcode, verify it appears in Target → Build Phases → Copy Bundle Resources.
- Use exact filenames in `Bundle.main.url(forResource:withExtension:)` calls — match the filename in Xcode (without path components).
- Always nil-check the result and provide a fallback or error message.

**Example verification code:**
```swift
if let url = Bundle.main.url(forResource: "markdown-it.min", withExtension: "js") {
    print("✓ Found markdown-it.js")
} else {
    print("✗ markdown-it.js not in bundle — check Copy Bundle Resources")
}
```

**Warning signs:**
- `Bundle.main.url` returns nil for .js files.
- WKUserScript doesn't inject (no error, just silent failure).
- markdown-it JavaScript is not available (console error: "markdown-it is not defined").

### Pitfall 5: Editor Text Out of Sync When Toggling Between Edit and Preview

**What goes wrong:** User edits text, switches to preview, toggles back to edit, and the text shown is stale or the cursor is in the wrong place.

**Why it happens:** Code re-reads the UIDocument on each preview toggle instead of keeping the in-memory UITextView string as the source of truth. Or the document's content changes while preview is active.

**How to avoid:**
- When showing preview, capture the *current* UITextView.text to pass to the renderer.
- Do NOT re-read from the UIDocument when toggling back to editor.
- Keep a single source of truth: UITextView.text is the current content; only save to disk on explicit user save action.
- Implement `UITextViewDelegate.textViewDidChange` to update a stored reference to the current markdown string if needed for async preview rendering.

**Warning signs:**
- Text differs after edit → preview → edit cycle.
- Cursor position changes unexpectedly.
- Undo/redo state is lost when toggling between edit and preview.

---

## Code Examples

Verified patterns from official sources and project conventions:

### Example 1: Basic WKWebView Setup for Markdown Rendering

```swift
// Source: Apple WKWebView Documentation + Project Architecture
import SwiftUI
import WebKit

struct PreviewView: UIViewRepresentable {
    let markdownString: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let userContent = WKUserContentController()

        // Inject CSS with prefers-color-scheme support
        let cssInjection = """
        var style = document.createElement('style');
        style.textContent = `
        :root { color-scheme: light dark; }
        body { font-family: -apple-system, sans-serif; padding: 16px; }
        h1 { font-size: 2em; margin-top: 24px; }
        h2 { font-size: 1.5em; }
        h3 { font-size: 1.25em; }
        code { font-family: Menlo, monospace; background: var(--code-bg); }
        @media (prefers-color-scheme: dark) {
            body { background: #1a1a1a; color: #fff; }
            code { --code-bg: #2a2a2a; }
        }
        @media (prefers-color-scheme: light) {
            code { --code-bg: #f5f5f5; }
        }
        `;
        document.head.appendChild(style);
        """

        let cssScript = WKUserScript(
            source: cssInjection,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        userContent.addUserScript(cssScript)

        config.userContentController = userContent
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let html = """
        <!DOCTYPE html>
        <html>
        <head><meta charset="UTF-8"><meta name="viewport" content="width=device-width"></head>
        <body>
            <div id="content">\(markdownString.escapingHTML())</div>
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Safe to execute JS now if needed
        }
    }
}
```

### Example 2: Markdown-it Integration with Plugin for Tables

```swift
// Source: markdown-it Documentation + Common GFM patterns
// Note: markdown-it v14.1.1 supports tables via markdown-it-table plugin

let markdownItSetup = """
// Initialize parser with table plugin
const md = window.markdownit({
    html: false,
    linkify: false,  // Don't auto-linkify URLs
    typographer: false
});

// Table plugin must be loaded separately (bundled as markdown-it-table.js)
if (window.markdownItTable) {
    md.use(window.markdownItTable.default);
}

function renderMarkdown(markdownText) {
    const html = md.render(markdownText);
    document.getElementById('content').innerHTML = html;
}

// Expose for Swift to call
window.renderMarkdown = renderMarkdown;
"""
```

### Example 3: Link Handling with SFSafariViewController

```swift
// Source: Apple WKNavigationDelegate Documentation + SafariServices
import SafariServices

class MarkdownRendererController: UIViewController, WKNavigationDelegate {
    @IBOutlet weak var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        webView.navigationDelegate = self
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        // Check if this is a user-clicked link (not initial page load)
        if navigationAction.navigationType == .linkActivated,
           let url = navigationAction.request.url,
           url.scheme == "http" || url.scheme == "https" {

            // Prevent default (would open Safari)
            decisionHandler(.cancel)

            // Open in in-app SFSafariViewController instead
            let safariVC = SFSafariViewController(url: url)
            safariVC.modalPresentationStyle = .popover
            self.present(safariVC, animated: true)
        } else {
            // Allow other navigations (document load, etc.)
            decisionHandler(.allow)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("✓ Markdown preview loaded successfully")
        // Safe to execute custom JS here if needed
    }
}
```

### Example 4: Inline Code Block with Syntax Highlighting

```swift
// Markdown input:
// ```swift
// let greeting = "Hello, World!"
// print(greeting)
// ```
//
// Expected HTML (markdown-it + highlight.js):
// <pre><code class="language-swift hljs">
//   <span class="hljs-keyword">let</span> greeting = <span class="hljs-string">"Hello, World!"</span>
//   ...
// </code></pre>

// CSS to style highlighted code:
let highlightCss = """
.hljs-keyword { color: #a71d5d; }      /* purple for keywords */
.hljs-string { color: #183691; }       /* blue for strings */
.hljs-number { color: #0086b3; }       /* blue for numbers */

@media (prefers-color-scheme: dark) {
    .hljs-keyword { color: #ff7b72; }
    .hljs-string { color: #79c0ff; }
    .hljs-number { color: #79c0ff; }
}
"""
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| UIWebView | WKWebView | iOS 9+ (2015) | UIWebView deprecated iOS 12+; WKWebView required for modern apps, better performance, JavaScript execution |
| Manual HTML generation | markdown-it library | ~2019 | Libraries handle CommonMark, GFM, edge cases; custom parsing unreliable |
| Single light color scheme | CSS prefers-color-scheme + variables | WWDC 2019 | Automatic dark mode without code changes; system appearance respected |
| JavaScript console.log | WKScriptMessageHandler | iOS 8+ | Enables web-to-app messaging; needed for advanced interop |

**Deprecated/outdated:**
- UIWebView: Removed from iOS 15+; never use for new projects.
- Manual regex-based Markdown: Breaks on nested structures, tables, code blocks. Use markdown-it.
- Hard-coded CSS colors: No dark mode support. Always use CSS variables + prefers-color-scheme.

---

## Open Questions

1. **Should we bundle markdown-it or fetch from CDN?**
   - What we know: State says "bundled in app bundle, no network." CDN adds dependency, privacy concerns.
   - What's unclear: Bundle size impact of markdown-it + highlight.js as unminified .js files.
   - Recommendation: Start bundled (requirement from STATE.md). Can optimize to minified/gzipped later if bundle size becomes issue.

2. **Does highlight.js need all 200+ language definitions or can we trim?**
   - What we know: Code blocks in markdown often have language hints (```swift, ```python). highlight.js supports all.
   - What's unclear: Whether we need all languages or can ship only a curated subset (JS, Python, Swift, etc.).
   - Recommendation: Ship full highlight.js for v1 (simplicity). Phase 6 can optimize if needed.

3. **How do we test rendering accuracy for all markdown elements?**
   - What we know: XCTest is the framework (established in v1.1).
   - What's unclear: How to assert on WKWebView-rendered output (DOM inspection? screenshot tests? regex on innerHTML?).
   - Recommendation: Phase 5 tests should focus on HTML generation correctness (markdown string → HTML string), not visual pixel-perfect rendering. Visual testing deferred to Phase 6 if needed.

4. **Should table rendering use CSS Grid or HTML table elements?**
   - What we know: Markdown tables convert to HTML `<table>` elements via markdown-it plugin.
   - What's unclear: Whether to enhance with CSS Grid for better layout control or keep plain HTML tables.
   - Recommendation: Keep plain HTML tables (simplicity, compatibility). CSS Grid optimization deferred.

---

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (system bundled with Xcode) |
| Config file | None — XCTest auto-discovers tests in `*Tests.swift` files |
| Quick run command | `xcodebuild test -scheme MarkdownEditor -only-testing MarkdownEditorTests/MarkdownRendererTests` |
| Full suite command | `xcodebuild test -scheme MarkdownEditor` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| PREV-02 | Headings H1/H2/H3 render with distinct sizes and weights | unit | `xcodebuild test -only-testing MarkdownEditorTests/MarkdownRendererTests/testHeadingsRenderWithVisualHierarchy` | ❌ Wave 0 |
| PREV-03 | `**bold**` and `*italic*` render as styled text (markers removed) | unit | `xcodebuild test -only-testing MarkdownEditorTests/MarkdownRendererTests/testBoldAndItalicRenderAsStyled` | ❌ Wave 0 |
| PREV-04 | Bullet lists and numbered lists render with indentation | unit | `xcodebuild test -only-testing MarkdownEditorTests/MarkdownRendererTests/testListsRenderWithIndentation` | ❌ Wave 0 |
| PREV-05 | Fenced code blocks render with monospace font | unit | `xcodebuild test -only-testing MarkdownEditorTests/MarkdownRendererTests/testCodeBlocksRenderMonospace` | ❌ Wave 0 |
| PREV-06 | Inline `code` renders with monospace font | unit | `xcodebuild test -only-testing MarkdownEditorTests/MarkdownRendererTests/testInlineCodeRendersMonospace` | ❌ Wave 0 |
| PREV-07 | Markdown tables render as visual grid with borders | unit | `xcodebuild test -only-testing MarkdownEditorTests/MarkdownRendererTests/testTablesRenderAsGrid` | ❌ Wave 0 |
| PREV-09 | Rendered HTML respects system light/dark mode (CSS prefers-color-scheme) | unit | `xcodebuild test -only-testing MarkdownEditorTests/MarkdownRendererTests/testDarkModeCSS` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `xcodebuild test -only-testing MarkdownEditorTests/MarkdownRendererTests`
- **Per wave merge:** Full test suite: `xcodebuild test -scheme MarkdownEditor`
- **Phase gate:** All markdown renderer tests passing (green) before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `MarkdownEditorTests/MarkdownRendererTests.swift` — unit tests for HTML generation (headings, bold/italic, lists, code blocks, tables, dark mode)
- [ ] `MarkdownRenderer.swift` — core class that orchestrates markdown-it parsing + CSS injection
- [ ] `PreviewView.swift` — SwiftUI UIViewRepresentable wrapper for WKWebView
- [ ] Bundle resources: `markdown-it.min.js`, `highlight.min.js`, `markdown-preview.css` — verify in Copy Bundle Resources build phase
- [ ] Framework install: None — XCTest and WebKit are system bundled

*(All gaps are implementation work; no new test framework setup needed)*

---

## Sources

### Primary (HIGH confidence)
- [Apple WKWebView Documentation](https://developer.apple.com/documentation/webkit/wkwebview) — Core API reference
- [Apple WKNavigationDelegate Documentation](https://developer.apple.com/documentation/webkit/wknavigationdelegate/webview(_:decidepolicyfor:decisionhandler:)-2ni62) — Link interception pattern
- [Apple WWDC 2019: Supporting Dark Mode in Web Content](https://developer.apple.com/videos/play/wwdc2019/511/) — Official dark mode guidance
- [markdown-it GitHub Repository](https://github.com/markdown-it/markdown-it) — Library docs, v14.1.1 verified active Feb 2026
- [highlight.js GitHub Repository](https://github.com/highlightjs/highlight.js) — Syntax highlighting library, v11.9.0+ current
- [Apple SFSafariViewController Documentation](https://developer.apple.com/documentation/safariservices/sfsafariviewcontroller) — In-app browsing pattern

### Secondary (MEDIUM confidence)
- [Hacking with Swift: WKWebView Guide](https://www.hackingwithswift.com/articles/112/the-ultimate-guide-to-wkwebview) — Practical examples, link handling
- [Supporting Dark Mode In WKWebView - Use Your Loaf](https://useyourloaf.com/blog/supporting-dark-mode-in-wkwebview/) — Dark mode CSS patterns
- [SwiftUI Advanced: WKWebView Integration - Design+Code](https://designcode.io/swiftui-advanced-handbook-wkwebview/) — UIViewRepresentable patterns
- [JavaScript Manipulation on iOS Using WebKit - Capital One](https://www.capitalone.com/tech/software-engineering/javascript-manipulation-on-ios-using-webkit/) — JS injection patterns

### Tertiary (LOW confidence)
- [MarkdownView iOS Library - GitHub](https://github.com/keitaoouchi/MarkdownView) — Reference implementation (not selected for this phase, but shows WKWebView + markdown-it pattern)
- [CommonMark Specification](https://spec.commonmark.org/0.28/) — Markdown standard reference

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — WKWebView, markdown-it, highlight.js are established patterns with official docs and active maintenance
- Architecture: HIGH — Dark mode via prefers-color-scheme, link interception, JS injection all officially documented and verified
- Pitfalls: HIGH — Common gotchas sourced from official docs (async loading, dark mode not affected by UIView overrides, navigation delegate requirement) and practical projects
- Validation: HIGH — XCTest is standard; test mapping is straightforward (HTML generation → unit tests, no UI testing needed for this phase)

**Research date:** 2026-03-27
**Valid until:** 2026-04-10 (stable libraries; markdown-it and highlight.js unlikely to change API)
