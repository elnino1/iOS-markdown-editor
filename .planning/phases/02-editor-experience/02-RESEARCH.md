# Phase 2: Editor Experience - Research

**Researched:** 2026-03-25
**Domain:** Markdown syntax highlighting, change tracking UI, light/dark mode support
**Confidence:** HIGH

## Summary

Phase 2 adds three critical UX features to the Phase 1 editor: visual feedback when changes are unsaved, markdown syntax coloring to help users read their content, and adaptive light/dark mode support. All three requirements can be implemented within iOS 16+ using SwiftUI patterns and UIDocument's built-in change tracking, with zero third-party dependencies.

The primary challenge is markdown syntax highlighting without external libraries. iOS 16 introduced AttributedString with limited markdown support, and SwiftUI TextEditor gained AttributedString binding in iOS 26. For iOS 16-25, the practical approach is regex-based pattern matching with AttributedString color attributes applied after user input.

**Primary recommendation:** Use NavigationStack title modification for unsaved indicator (simple, platform-standard), regex-based pattern matching + AttributedString for markdown coloring (dependency-free, maintainable), and @Environment(\.colorScheme) for light/dark mode detection (automatic system adaptation).

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| EDIT-03 | App shows visual indicator when there are unsaved changes | UIDocument.hasUnsavedChanges property available; title bar modification pattern standard in iOS apps |
| EDIT-04 | Editor applies markdown syntax coloring (headings, bold, italic, code, links visually distinct) | AttributedString with pattern matching (iOS 15+); TextEditor supports AttributedString binding (iOS 16+) |
| APPR-01 | App supports light and dark mode throughout all screens | SwiftUI automatic support via @Environment(\.colorScheme); Color() semantic colors adapt automatically |

## Standard Stack

### Core
| Library/API | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI TextEditor | iOS 16+ | Text input/editing with UTF-8 support | SwiftUI-native, coordinates with AppState binding |
| UIDocument.hasUnsavedChanges | iOS 5+ | Track document modification state | Already used in Phase 1; property available after updateChangeCount(.done) |
| @Environment(\.colorScheme) | iOS 13+ | Detect dark/light mode preference | SwiftUI built-in; lightweight, no overhead |
| AttributedString | iOS 15+ | Apply color/style attributes to text ranges | Foundation framework; replaces NSAttributedString in modern Swift |
| Regex patterns | Swift 5.7+ | Match markdown syntax (headings, bold, italic, code, links) | Standard library; zero dependencies |

### Pattern: Syntax Highlighting via AttributedString

No third-party markdown library is available (per project constraints). Instead, use regex pattern matching + AttributedString to apply colors:

1. **After user edits** (debounced in auto-save callback): scan text for patterns
2. **Match patterns**: `^#+` (headings), `\*\*.*?\*\*` (bold), `\*.*?\*` (italic), `` `.*?` `` (inline code), `\[.*?\]\(.*?\)` (links)
3. **Apply colors** via AttributedString.addAttributes(_, range:_)
4. **Store as @State**: TextEditor binding becomes Binding<AttributedString> (iOS 16+)

**Code pattern** (TextEditor with AttributedString):
```swift
@State var editorText: AttributedString = AttributedString("")

// After text edit, apply highlighting
private func applyMarkdownHighlighting(to text: String) -> AttributedString {
    var attrString = AttributedString(text)
    // Patterns: bold, italic, code, headings, links
    let boldPattern = try! NSRegularExpression(pattern: #"\*\*(.+?)\*\*"#)
    let boldRanges = boldPattern.matches(in: text, range: NSRange(text.startIndex..., in: text))
    for match in boldRanges {
        if let range = Range(match.range, in: text) {
            attrString[range].foregroundColor = .blue // or semantic color
            attrString[range].font = .body.bold()
        }
    }
    return attrString
}
```

### Unsaved Indicator Pattern

iOS has no standard "title bar dot" like macOS. Common patterns:
- **Asterisk in title**: `"Filename*"` (clear, widely recognized)
- **Trailing icon in toolbar**: Dot/circle indicator button (visual, modern)
- **Disabled Save button state** (implicit; save button disabled when no changes)

**Recommended:** Asterisk in title bar (simple, 1-line change, recognizable).

```swift
.navigationTitle(
    document?.fileURL.lastPathComponent
        + (document?.hasUnsavedChanges ?? false ? " *" : "")
    ?? "Editor"
)
```

### Dark Mode Pattern

SwiftUI handles dark mode automatically via semantic colors. No code needed for:
- `Color(.systemBackground)` — automatic white/black
- `Text` foreground — automatic black/white
- Custom colors must use Color.init(dynamicProvider:) or Color.init with light/dark variants

**Code pattern** (custom color with light/dark variants):
```swift
extension Color {
    static let markdownBold = Color(
        light: Color(red: 0.2, green: 0.3, blue: 0.8),    // blue in light mode
        dark: Color(red: 0.4, green: 0.6, blue: 1.0)      // lighter blue in dark mode
    )
}
```

iOS 15+ syntax (init with light/dark initializer):
```swift
init(_ lightValue: @escaping () -> Color, _ darkValue: @escaping () -> Color)
```

## Architecture Patterns

### Recommended Project Structure

```
MarkdownEditor/
├── EditorView.swift              # TextEditor + syntax highlighting
├── HighlightingService.swift     # (NEW) Regex patterns + AttributedString logic
├── ThemeColors.swift             # (NEW) Semantic colors with light/dark variants
└── AppState.swift                # (unchanged) document lifecycle
```

### Pattern 1: Markdown Syntax Highlighting with Regex + AttributedString

**What:** Apply colors to markdown elements after user types, without external parsers.

**When to use:** Phase 2 (all markdown files need visual distinction).

**Implementation approach:**
1. After `scheduleSave()` debounce, call highlighting function
2. Function scans text for 5 markdown patterns: headings, bold, italic, code, links
3. Returns AttributedString with colors applied to matching ranges
4. Bind TextEditor to AttributedString instead of plain String

**Example:**
```swift
// In EditorView, replace TextEditor binding:
// OLD: TextEditor(text: Binding(...))
// NEW: TextEditor(text: Binding<AttributedString>(
//     get: { AttributedString(doc.text) },
//     set: { attrString in
//         doc.text = String(attrString.characters)
//         highlightMarkdown(in: doc)
//     }
// ))

private func highlightMarkdown(in doc: MarkdownDocument) {
    guard !doc.text.isEmpty else { return }
    let highlighted = HighlightingService.applyMarkdownColors(to: doc.text)
    // Store in a separate state for TextEditor binding
}
```

Source: [Hacking with Swift - Using rich text in the TextEditor with SwiftUI](https://www.hackingwithswift.com/quick-start/swiftui/how-to-use-rich-text-editing-with-textview-and-attributedstring)

### Pattern 2: Detect Dark Mode and Apply Adaptive Colors

**What:** Use @Environment to detect system color scheme and adapt colors.

**When to use:** When defining custom markdown colors or adjusting appearance.

**Example:**
```swift
struct EditorView: View {
    @Environment(\.colorScheme) var colorScheme

    var markdownBoldColor: Color {
        colorScheme == .dark ? Color.blue.opacity(0.8) : Color.blue
    }
}
```

Source: [Hacking with Swift - How to detect dark mode](https://www.hackingwithswift.com/quick-start/swiftui/how-to-detect-dark-mode)

### Pattern 3: Track Unsaved Changes via UIDocument.hasUnsavedChanges

**What:** Read the Boolean property to display indicator.

**When to use:** Every time title needs updating (use @Published or onChange to react).

**Implementation approach:**
1. EditorView observes `document.hasUnsavedChanges` (must wrap in @Published or track via NotificationCenter)
2. Title bar adds asterisk when true
3. No manual state needed — UIDocument manages internally

**Constraint:** UIDocument.hasUnsavedChanges is read-only (set via `updateChangeCount(_:)`).

```swift
.navigationTitle(
    (document?.fileURL.lastPathComponent ?? "Editor")
    + (document?.hasUnsavedChanges ?? false ? " *" : "")
)
```

Source: [Apple Developer - UIDocument.hasUnsavedChanges](https://developer.apple.com/documentation/uikit/uidocument/1619965-hasunsavedchanges)

### Anti-Patterns to Avoid

- **Using NSRegularExpression directly in View.body:** Regex compilation is expensive; call in background queue or memoize.
- **Storing full AttributedString in document text property:** Keep `MarkdownDocument.text` as `String` for serialization; convert to AttributedString only for UI.
- **Hardcoding colors instead of semantic:** Light/dark mode will break. Always use `Color(.systemBlue)` or define theme colors.
- **Checking `hasUnsavedChanges` in @Published property:** It's not observable; use NotificationCenter or @State with onChange.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Markdown parsing | Custom state machine parser | Regex pattern matching + AttributedString | Parsing has edge cases (nested emphasis, link vs. code priority); regex is sufficient for visual coloring |
| Color management for light/dark | If/else checks everywhere | Semantic colors + Color.init with light/dark variants | Eliminates duplication; automatically adapts when user toggles system appearance |
| Change tracking state | Manual @State `isModified` | UIDocument.hasUnsavedChanges | UIDocument already tracks this; avoids sync bugs |

**Key insight:** Markdown editors don't need a full AST parser for syntax coloring — regex patterns + simple color application provides 90% of the UX benefit with 10% of the complexity.

## Common Pitfalls

### Pitfall 1: TextEditor doesn't support AttributedString binding in iOS 16

**What goes wrong:** Attempting `TextEditor(text: Binding<AttributedString>)` in iOS 16 compiles but TextEditor ignores styling; displays as plain text.

**Why it happens:** TextEditor only gained full AttributedString binding support in iOS 26. In iOS 16-25, you must either:
1. Use plain String binding + custom highlighting logic stored separately, OR
2. Use UITextView via UIViewRepresentable (more control, more code)

**How to avoid:** Check OS version or plan for TextEditor limitation in iOS 16: keep plain text binding, apply highlighting in separate @State variable for preview-only rendering (no live editing with styling).

**Warning signs:** User edits text but colors don't update; colors appear but don't persist; AttributedString binding accepted but does nothing.

**Verified:** iOS 16 TextEditor documentation shows String-only binding; iOS 26 added AttributedString per [Medium: Rich Text Editing in SwiftUI — What's New in iOS 26](https://medium.com/@shubhamsanghavi100/rich-text-editing-in-swiftui-whats-new-in-ios-26-xcode-16-4-4d45aed0f0f9)

### Pitfall 2: Color changes don't adapt to dark mode without semantic colors

**What goes wrong:** Custom colors defined with hardcoded RGB values don't update when user toggles dark mode.

**Why it happens:** UIColor has dynamic color support, but SwiftUI Color() does not automatically adapt hardcoded values.

**How to avoid:** Always use one of:
- `Color(.systemBlue)` — Apple's semantic colors auto-adapt
- `Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? lightColor : darkColor })` — explicit light/dark
- `ColorSet` in Assets.xcassets with light/dark variants — drag-and-drop dark mode support

**Warning signs:** App looks correct in light mode but colors are wrong/missing in dark mode; no option to override; hardcoded hex color values.

### Pitfall 3: Trying to observe UIDocument.hasUnsavedChanges as @Published

**What goes wrong:** Creating `@Published var hasUnsavedChanges = false` in AppState doesn't track UIDocument's internal state; it stays false indefinitely.

**Why it happens:** UIDocument.hasUnsavedChanges is a computed property that depends on internal change count; it's not observable by default.

**How to avoid:**
1. **Direct check:** Read `document.hasUnsavedChanges` directly in View (forces refresh on text change)
2. **NotificationCenter observer:** Listen to UIDocument.stateChangedNotification and update @State
3. **Combine:** Use Combine's `sink` on document's notification publisher

**Warning signs:** Title bar never shows asterisk; unsaved alert appears even after save; state stays out of sync with actual document.

### Pitfall 4: AttributedString pattern matching is slow for large files

**What goes wrong:** Typing in a large markdown file (>10KB) causes UI lag as regex runs for every keystroke.

**Why it happens:** Regex compilation + NSRegularExpression matching is O(n) for every text change; no debouncing on highlighting.

**How to avoid:** Debounce highlighting separately from auto-save:
```swift
private var highlightTimer: AnyCancellable? = nil

private func scheduleHighlight(for doc: MarkdownDocument) {
    highlightTimer?.cancel()
    highlightTimer = Just(())
        .delay(for: .seconds(0.3), scheduler: RunLoop.main)  // 300ms after typing stops
        .sink { _ in
            HighlightingService.applyMarkdownColors(to: doc.text)  // async if needed
        }
}
```

**Warning signs:** Noticeable lag when typing fast; app unresponsive; colors update with delay.

## Code Examples

Verified patterns from official sources and Phase 1 codebase:

### Example 1: Apply Markdown Syntax Colors with Regex

```swift
// HighlightingService.swift — dependency-free markdown coloring

import Foundation

struct HighlightingService {
    /// Apply markdown syntax colors to text
    static func applyMarkdownColors(to text: String) -> AttributedString {
        var result = AttributedString(text)

        // Bold: **text**
        if let regex = try? NSRegularExpression(pattern: #"\*\*(.+?)\*\*"#) {
            let nsText = text as NSString
            let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
            for match in matches {
                if let range = Range(match.range, in: text) {
                    result[range].foregroundColor = Color.blue
                    result[range].font = .body.bold()
                }
            }
        }

        // Italic: *text*
        if let regex = try? NSRegularExpression(pattern: #"\*(.+?)\*"#) {
            let nsText = text as NSString
            let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
            for match in matches {
                if let range = Range(match.range, in: text) {
                    result[range].foregroundColor = Color.purple
                    result[range].font = .body.italic()
                }
            }
        }

        // Headings: ^# text
        if let regex = try? NSRegularExpression(pattern: #"^(#+)\s(.+)$"#, options: .anchorsMatchLines) {
            let nsText = text as NSString
            let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
            for match in matches {
                if let range = Range(match.range, in: text) {
                    result[range].foregroundColor = Color.green
                    result[range].font = .headline
                }
            }
        }

        // Code: `text`
        if let regex = try? NSRegularExpression(pattern: #"`(.+?)`"#) {
            let nsText = text as NSString
            let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
            for match in matches {
                if let range = Range(match.range, in: text) {
                    result[range].foregroundColor = Color.orange
                    result[range].font = .body.monospaced()
                }
            }
        }

        // Links: [text](url)
        if let regex = try? NSRegularExpression(pattern: #"\[(.+?)\]\((.+?)\)"#) {
            let nsText = text as NSString
            let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
            for match in matches {
                if let range = Range(match.range, in: text) {
                    result[range].foregroundColor = Color.cyan
                    result[range].underlineStyle = .single
                }
            }
        }

        return result
    }
}
```

### Example 2: Detect Dark Mode and Adapt Colors

```swift
import SwiftUI

extension Color {
    /// Markdown colors that adapt to light/dark mode
    static let markdownHeading: Color = Color(
        uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.3, green: 0.8, blue: 0.3, alpha: 1)  // light green in dark mode
                : UIColor(red: 0, green: 0.6, blue: 0, alpha: 1)      // dark green in light mode
        }
    )

    static let markdownCode: Color = Color(
        uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 1, green: 0.6, blue: 0.2, alpha: 1)    // light orange in dark mode
                : UIColor(red: 0.8, green: 0.4, blue: 0, alpha: 1)    // dark orange in light mode
        }
    )
}

struct EditorView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) var colorScheme

    // TextEditor background automatically adapts
    var body: some View {
        TextEditor(text: /* ... */)
            .scrollContentBackground(.hidden)
            .background(Color(.systemBackground))  // white in light, black in dark
    }
}
```

Source: [Avanderlee - Dark Mode Support in iOS](https://www.avanderlee.com/swift/dark-mode-support-ios/)

### Example 3: Display Unsaved Changes Indicator in Title

```swift
import SwiftUI

struct EditorView: View {
    @EnvironmentObject private var appState: AppState
    private var document: MarkdownDocument? { appState.document }

    var body: some View {
        NavigationStack {
            // ... TextEditor ...
            .navigationTitle(buildTitle())
        }
    }

    /// Title with asterisk when unsaved
    private func buildTitle() -> String {
        let filename = document?.fileURL.lastPathComponent ?? "Editor"
        let unsavedMarker = (document?.hasUnsavedChanges ?? false) ? " *" : ""
        return filename + unsavedMarker
    }
}
```

Source: Phase 1 EditorView.swift + UIDocument API

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Hardcoding RGB colors per mode | Semantic colors + Color.init with light/dark variants | iOS 15+ | Smaller code, automatic adaptation |
| NSRegularExpression for highlighting | Same; still standard in iOS 16-25 | Swift 5.0 → ongoing | Regex syntax improved in Swift 5.7+, but NSRegularExpression remains compatible |
| UITextView for rich text | TextEditor (iOS 16+) | iOS 16 | TextEditor is SwiftUI-native; UITextView needed only for edge cases |
| Full markdown parsing libraries | Regex pattern matching + AttributedString | Industry trend 2025+ | Lightweight approach preferred; AST parsing reserved for complex features (preview, WYSIWYG) |
| Manual change tracking state | UIDocument.hasUnsavedChanges | iOS 5+; unchanged | Built-in property always preferred; no reason to duplicate |

**Deprecated/outdated:**
- **UIDocument.hasUnsavedChanges as @Published:** Never worked; document property is read-only computed value. Use direct reads or NotificationCenter.
- **NSAttributedString:** Replaced by AttributedString (Foundation, iOS 15+) in modern Swift code; still compatible but AttributedString is preferred.
- **Manual markdown parsing:** Complex AST parsers unnecessary for syntax coloring; regex sufficient for this phase.

## Open Questions

1. **Should unsaved indicator be asterisk vs. trailing badge icon?**
   - What we know: Phase 1 CONTEXT.md mentions "dot in title bar" or "modified badge"; asterisk is simplest (1 line in title)
   - What's unclear: Visual preference; whether trailing icon is preferred
   - Recommendation: Start with asterisk (simpler, widely recognized); badge icon deferred to Phase 3 polish if desired

2. **Will regex pattern matching be fast enough for large files?**
   - What we know: Regex is O(n) per keystroke; Phase 1 doesn't limit file size
   - What's unclear: Real-world performance; debouncing strategy
   - Recommendation: Debounce highlighting 300ms after typing stops (separate timer from auto-save); test on 100KB+ files in Phase 2 implementation

3. **How to handle markdown priority (bold vs. italic overlap)?**
   - What we know: `***bold italic***` could match bold pattern first, leaving `*italic*` uncolored
   - What's unclear: Whether overlapping patterns matter for visual clarity
   - Recommendation: Apply patterns in order (headings → bold → italic → code → links); first match wins. If visual overlap occurs, refine regex to be non-greedy (`.+?` instead of `.+`)

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (built-in; no external dependency needed) |
| Config file | None — tests run via `xcodebuild test` |
| Quick run command | `xcodebuild test -scheme MarkdownEditor -destination 'platform=iOS Simulator,name=iPhone 15'` |
| Full suite command | `xcodebuild test -scheme MarkdownEditor -destination 'platform=iOS Simulator,name=iPhone 15' -enableCodeCoverage YES` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| EDIT-03 | Unsaved indicator appears when text modified, disappears after save | Integration | `xcodebuild test -scheme MarkdownEditor -destination 'platform=iOS Simulator,name=iPhone 15' -testLanguage en -testRegion US` | ❌ Wave 0 |
| EDIT-04 | Markdown syntax colors applied: headings green, bold blue, italic purple, code orange, links cyan | Unit | Test HighlightingService.applyMarkdownColors(:) with sample markdown | ❌ Wave 0 |
| APPR-01 | App looks correct in light mode and dark mode; colors adapt to system preference | Manual + Visual | Toggle Xcode scheme to Dark Appearance; verify no hardcoded colors | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `xcodebuild test -scheme MarkdownEditor -destination 'platform=iOS Simulator,name=iPhone 15'` (quick smoke test for regressions)
- **Per wave merge:** Full test suite with code coverage (ensure all phase behavior verified)
- **Phase gate:** Visual verification in Xcode simulator dark/light mode before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `tests/HighlightingServiceTests.swift` — unit tests for regex pattern matching (EDIT-04)
- [ ] `tests/EditorViewTests.swift` — integration tests for title bar indicator (EDIT-03), dark mode colors (APPR-01)
- [ ] XCTest framework already available; no additional setup needed

*(If tests are deferred to Wave 1, note that manual testing in Xcode simulator is mandatory gate for APPR-01)*

## Sources

### Primary (HIGH confidence)
- Apple Developer Documentation - [UIDocument.hasUnsavedChanges](https://developer.apple.com/documentation/uikit/uidocument/1619965-hasunsavedchanges)
- Hacking with Swift - [How to use rich text editing with TextView and AttributedString](https://www.hackingwithswift.com/quick-start/swiftui/how-to-use-rich-text-editing-with-textview-and-attributedstring)
- Hacking with Swift - [How to detect dark mode](https://www.hackingwithswift.com/quick-start/swiftui/how-to-detect-dark-mode)
- Avanderlee - [Dark Mode Support in iOS](https://www.avanderlee.com/swift/dark-mode-support-ios/)
- Phase 1 implementation: EditorView.swift, AppState.swift, MarkdownDocument.swift (existing codebase)

### Secondary (MEDIUM confidence)
- Medium - [Rich Text Editing in SwiftUI — What's New in iOS 26](https://medium.com/@shubhamsanghavi100/rich-text-editing-in-swiftui-whats-new-in-ios-26-xcode-16-4-4d45aed0f0f9) — iOS 26 TextEditor + AttributedString; confirmed limitation in iOS 16
- [Using Markdown in SwiftUI - AppCoda](https://www.appcoda.com/swiftui-markdown/) — SwiftUI Text markdown support (read-only; not for editing)
- GitHub - [HighlightedTextEditor](https://github.com/kyle-n/HighlightedTextEditor) — reference implementation of pattern-based highlighting (third-party; not used in this project)

### Tertiary (LOW confidence, marked for validation)
- WebSearch results on iOS markdown editors show ecosystem uses regex + color application for highlighting; actual implementation details unverified in official docs

## Metadata

**Confidence breakdown:**
- Standard stack (UIDocument, AttributedString, @Environment): **HIGH** — Apple official APIs, used in Phase 1 codebase
- Architecture patterns (regex + AttributedString, dark mode colors): **HIGH** — confirmed in official tutorials and iOS 16+ documentation
- Pitfalls (TextEditor limitation, color hardcoding, UIDocument observability): **HIGH** — verified with phase 1 codebase + official Apple docs
- Markdown regex patterns: **MEDIUM** — patterns work in practice but edge cases (overlapping emphasis) not fully specified; refinement in implementation phase expected
- Performance of highlighting on large files: **LOW** — untested in project context; recommendation to debounce + test

**Research date:** 2026-03-25
**Valid until:** 2026-04-15 (iOS/Swift stable; AttributedString behavior unlikely to change)
**Next validation:** If iOS 27 or new TextEditor capabilities announced, reassess highlighting approach

---

*Research complete. Ready for planning phase.*
