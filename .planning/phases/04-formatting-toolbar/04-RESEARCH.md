# Phase 4: Formatting Toolbar - Research

**Researched:** 2026-03-26
**Domain:** iOS keyboard-docked formatting toolbar for markdown editing
**Confidence:** HIGH

## Summary

Phase 4 adds a keyboard-docked toolbar enabling users to apply markdown formatting without typing syntax manually. This phase builds on the validated v1.0 stack (UITextView, UIDocument, Combine auto-save) and introduces text manipulation and undo/redo management complexity.

The core requirement is straightforward: present 7 buttons above the keyboard (Bold, Italic, Bullet, Table, Undo, Redo, Keyboard Dismiss) that modify text in the UITextView. However, the implementation complexity lies in three mechanical challenges: (1) preserving cursor position across multi-step text insertions, (2) integrating toolbar operations into the system UndoManager, and (3) handling NSRange calculations correctly with emoji and multi-byte characters.

The recommended approach uses SwiftUI's native `.toolbar(placement: .keyboard)` modifier (iOS 15+, fully supported on the project's iOS 16+ minimum) rather than UIKit's legacy inputAccessoryView pattern. All text modifications flow through UITextInput protocol methods (insertText, replace), never direct textStorage manipulation. Toolbar operations that involve multiple text insertions (bold wrapping = 2 insertions) are wrapped in atomic undo grouping so they undo/redo as single steps.

Critical pitfalls are well-documented and preventable with discipline: direct textStorage modification breaks undo stacks, cursor position loss from offset miscalculation, NSRange emoji corruption from UTF-16 vs grapheme cluster confusion, and syntax highlighting feedback loops (mitigated by the existing 300ms debounce in HighlightingService).

**Primary recommendation:** Implement toolbar via SwiftUI `.toolbar(placement: .keyboard)` modifier; route formatting operations through a `MarkdownTextEditor.Coordinator` method suite; use `UITextInput` protocol exclusively for text changes; register undo operations BEFORE text modification; test exhaustively with ASCII, emoji, CJK text, and multi-line selections before closing.

## Phase Requirements

| ID | Description | Research Support |
|---|---|---|
| TOOL-01 | Editor shows a formatting toolbar docked above the keyboard while editing | SwiftUI `.toolbar(placement: .keyboard)` is the native implementation pattern; toolbar automatically appears when editor is focused and dismisses when keyboard closes |
| TOOL-02 | User can tap a button in the toolbar to dismiss the keyboard | Keyboard dismiss button uses SF Symbol `keyboard.chevron.compact.down`; tap action calls textView.resignFirstResponder() to close keyboard while keeping editor in focus |
| FMT-01 | User can tap Bold to wrap selected text in `**markers**` or insert `**text**` if nothing selected | All text insertion via UITextInput.insertText/_replace, never direct textStorage; wrap operation is atomic (two insertions grouped via beginUndoGrouping/endUndoGrouping) |
| FMT-02 | User can tap Italic to wrap selected text in `*markers*` or insert `*text**` if nothing selected | Same pattern as bold; uses `*` markers instead of `**` |
| FMT-03 | User can tap Bullet to prefix the current line with `- ` | Line boundary detection uses NSString.lineRange(for:); never String.split(separator:) which breaks on platform line endings |
| FMT-04 | User can tap Table to insert a 3-column × 2-row markdown table template at the cursor | Table template is fixed format; insertion at cursor position calculated via NSRange |
| UNDO-01 | User can tap Undo in the toolbar to undo the last edit or formatting action | UndoManager must be registered BEFORE each text modification; observe canUndo property to disable button when stack empty |
| UNDO-02 | User can tap Redo in the toolbar to redo the last undone action | UndoManager observe canRedo property to disable button when stack empty |

## Standard Stack

### Core (Validated v1.0)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Swift | 5.10+ | Language | Mature async/await support; standard iOS development |
| SwiftUI | iOS 16+ | UI Framework | Native keyboard toolbar support via `.toolbar(placement: .keyboard)` modifier; cleaner than UIKit bridging |
| UITextView (UIViewRepresentable) | Built-in | Raw text editor | Better performance than SwiftUI TextEditor for syntax highlighting; NSAttributedString support; UITextInput protocol integration |
| UIDocument | Built-in | File coordination | Atomic read/write to original file location; handles concurrent access |
| Combine | iOS 13+ | Reactive patterns | Auto-save debounce (1.5s); file I/O callback handling |

### Text Manipulation & Undo (NEW for Phase 4)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| UITextInput protocol | Built-in | Text insertion/replacement | Standard iOS API for programmatic text changes; integrates with UndoManager; never use direct textStorage modification |
| UndoManager | Built-in | Undo/redo stack | System-standard undo tracking; toolbar operations must register before text modification to integrate properly |
| NSRange + NSString | Built-in | Position calculation | UTF-16 aware; safe for emoji and multi-byte characters; never use Swift String.count for position math |
| NSAttributedString | Built-in | Syntax highlighting | Markdown coloring via textStorage observer; preserves selection during re-highlighting via 300ms debounce |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `.toolbar(placement: .keyboard)` | UIKit inputAccessoryView | inputAccessoryView is legacy pattern; requires UIViewControllerRepresentable bridging; SwiftUI toolbar is cleaner for iOS 16+ |
| UITextView | TextEditor (SwiftUI) | TextEditor doesn't support NSAttributedString; TextEditor bindings ignore attributed text changes in iOS 16; UITextView gives us highlighting control |
| NSString for position math | Swift String.count | String.count uses grapheme clusters; NSString uses UTF-16 code units; emoji corruption if you mix them |

### Installation
```bash
# No new external dependencies for Phase 4
# Uses only built-in iOS frameworks:
# - SwiftUI (already present)
# - UIKit (already present)
# - Foundation NSString, NSRange, UndoManager (already present)
```

### Version Verification
- **Swift:** 5.10+ (project requirement; check with `swift --version`)
- **iOS deployment target:** 16.0+ (project requirement; .toolbar(placement: .keyboard) fully supported)
- **Xcode:** 15.1+ (Swift 5.10 toolchain)

## Architecture Patterns

### Recommended Project Structure
```
MarkdownEditor/
├── MarkdownTextEditor.swift          # UIViewRepresentable wrapping UITextView
│   └── Coordinator                   # UITextViewDelegate + formatting methods
├── EditorView.swift                  # SwiftUI view hosting MarkdownTextEditor
│   └── .toolbar(placement: .keyboard) # Formatting toolbar UI
├── HighlightingService.swift         # Syntax coloring (unchanged)
└── MarkdownDocument.swift            # File I/O (unchanged)
```

### Pattern 1: Toolbar Placement via SwiftUI Modifier
**What:** Add formatting toolbar buttons above keyboard using SwiftUI's native `.toolbar(placement: .keyboard)` modifier.

**When to use:** For iOS 15+ projects with UIViewRepresentable-wrapped UITextView. This is the modern pattern that replaces legacy UIKit inputAccessoryView approach.

**Example:**
```swift
// In EditorView.swift
struct EditorView: View {
    @EnvironmentObject private var appState: AppState
    @State private var canUndo = false
    @State private var canRedo = false

    var body: some View {
        NavigationStack {
            Group {
                if let doc = document {
                    MarkdownTextEditor(
                        text: Binding(...),
                        isHighlightingEnabled: !highlightingDisabled
                    )
                    .ignoresSafeArea(.keyboard)
                    .toolbar {
                        ToolbarItemGroup(placement: .keyboard) {
                            // Bold button
                            Button(action: { coordinator?.applyBold() }) {
                                Image(systemName: "bold")
                            }
                            .accessibilityLabel("Make text bold")

                            // Italic button
                            Button(action: { coordinator?.applyItalic() }) {
                                Image(systemName: "italic")
                            }
                            .accessibilityLabel("Make text italic")

                            // ... more buttons (bullet, table, undo, redo)

                            // Keyboard dismiss button (rightmost)
                            Button(action: { textView?.resignFirstResponder() }) {
                                Image(systemName: "keyboard.chevron.compact.down")
                            }
                            .accessibilityLabel("Dismiss keyboard")
                        }
                    }
                }
            }
        }
    }
}
```

### Pattern 2: Text Insertion via UITextInput Protocol
**What:** All text modifications (bold wrapping, bullet prefixing, table insertion) flow through `UITextInput` protocol methods, never direct `textStorage` mutation.

**When to use:** Every toolbar formatting action. This ensures UndoManager tracks changes and syntax highlighting observer fires correctly.

**Example:**
```swift
// In MarkdownTextEditor.Coordinator (extends UITextViewDelegate)
extension MarkdownTextEditor.Coordinator {
    /// Apply bold formatting to selected text (or insert placeholder if nothing selected)
    func applyBold() {
        guard let textView = self.textView else { return }

        let selectedRange = textView.selectedRange
        let nsString = textView.text as NSString

        // Register undo BEFORE modifying text
        textView.undoManager?.beginUndoGrouping()

        if selectedRange.length > 0 {
            // Text selected: wrap with **markers**
            let selectedText = nsString.substring(with: selectedRange)
            let wrapped = "**\(selectedText)**"

            // Use UITextInput to replace: this registers undo automatically
            let range = UITextRange(selectedRange: selectedRange)
            textView.replace(range, withText: wrapped)

            // Restore selection to wrapped text
            let newRange = NSRange(
                location: selectedRange.location + 2,
                length: selectedRange.length
            )
            textView.selectedRange = newRange
        } else {
            // No selection: insert placeholder
            textView.insertText("**text**")

            // Position cursor inside markers for editing
            textView.selectedRange = NSRange(
                location: selectedRange.location + 2,
                length: 4  // "text" length
            )
        }

        textView.undoManager?.endUndoGrouping()
        textView.undoManager?.setActionName("Make Bold")

        // Update binding to notify SwiftUI of text change
        text = textView.text
    }
}
```

### Pattern 3: Atomic Undo Grouping for Multi-Step Operations
**What:** Operations requiring multiple text insertions (e.g., bold = 2 insertions for opening and closing markers) must be wrapped in `beginUndoGrouping()`/`endUndoGrouping()` so they undo/redo as a single step.

**When to use:** Bold, Italic, any operation that requires inserting at multiple positions.

**Example:**
```swift
func applyBold() {
    guard let textView = self.textView else { return }

    let selectedRange = textView.selectedRange
    let nsString = textView.text as NSString

    if selectedRange.length > 0 {
        let selectedText = nsString.substring(with: selectedRange)

        // CRITICAL: Group all insertions as ONE undo step
        textView.undoManager?.beginUndoGrouping()

        // Insert opening marker
        let openingMarker = "**"
        let insertRange = UITextRange(selectedRange: NSRange(location: selectedRange.location, length: 0))
        textView.replace(insertRange, withText: openingMarker)

        // Insert closing marker (offset by opening marker length)
        let closingPosition = selectedRange.location + selectedRange.length + openingMarker.count
        let closingRange = UITextRange(selectedRange: NSRange(location: closingPosition, length: 0))
        textView.replace(closingRange, withText: openingMarker)

        textView.undoManager?.endUndoGrouping()
        textView.undoManager?.setActionName("Make Bold")

        // Restore selection inside markers
        textView.selectedRange = NSRange(
            location: selectedRange.location + 2,
            length: selectedRange.length
        )
    }

    text = textView.text
}
```

### Pattern 4: Cursor Position Preservation
**What:** Save selectedRange before text modification; recalculate offsets accounting for inserted text; restore selectedRange after operation.

**When to use:** Every formatting action that moves text around. This prevents cursor from jumping to end of document.

**Example:**
```swift
func applyBullet() {
    guard let textView = self.textView else { return }

    let selectedRange = textView.selectedRange
    let nsString = textView.text as NSString

    // Find the line containing the cursor
    let lineRange = nsString.lineRange(for: selectedRange)
    let lineText = nsString.substring(with: lineRange)

    // Prefix line with "- "
    let bulletPrefix = "- "
    let newLineText = bulletPrefix + lineText

    textView.undoManager?.beginUndoGrouping()

    // Replace entire line
    let replaceRange = UITextRange(selectedRange: lineRange)
    textView.replace(replaceRange, withText: newLineText)

    textView.undoManager?.endUndoGrouping()
    textView.undoManager?.setActionName("Add Bullet")

    // Restore cursor position (adjusted for prefix)
    let newPosition = selectedRange.location + bulletPrefix.count
    textView.selectedRange = NSRange(location: newPosition, length: 0)

    text = textView.text
}
```

### Anti-Patterns to Avoid

- **Direct textStorage modification:** `textView.textStorage.replaceCharacters(in:, with:)` bypasses UndoManager and breaks undo/redo. Always use UITextInput methods.
- **Ignoring selectedRange preservation:** Not saving cursor position before text modification causes cursor to jump to end of text or document. This confuses users and breaks chained formatting operations.
- **Using Swift String.count for NSRange calculations:** Swift counts grapheme clusters; NSRange/NSString counts UTF-16 code units. Emoji and combining characters corrupt if you mix these. Always use NSString for position math.
- **Modifying text during textViewDidChange delegate callback:** This creates feedback loops where the modification triggers another textViewDidChange, causing recursion or performance issues. Schedule modifications to run after delegate callback completes.
- **Immediate re-highlighting after toolbar action:** The 300ms debounce in HighlightingService prevents visual flicker from toolbar formatting followed by syntax highlighting. Don't bypass this; it's already working correctly.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Text insertion with undo tracking | Custom text modification logic via textStorage or string concatenation | UITextInput protocol (insertText, replace) | UITextInput is the documented iOS API for text changes; automatically integrates with UndoManager; direct textStorage modification breaks undo/redo and syntax highlighting |
| Undo/redo stack management | Custom stack tracking for formatting operations | UndoManager (built-in) | UndoManager is the system-standard undo API; integrates with keyboard shortcuts and undo gestures; custom stacks create duplicate functionality and bugs |
| Cursor position calculation after insertion | Manually tracking offset changes across insertions | NSRange + NSString methods | NSString.lineRange, NSString.substring methods are optimized for UTF-16; custom position tracking leads to emoji corruption and off-by-one errors |
| Keyboard toolbar presentation | Custom UIView wrapper with frame calculations | SwiftUI `.toolbar(placement: .keyboard)` modifier | SwiftUI toolbar is native iOS 15+ API; automatically handles keyboard appearance/dismissal animations; custom wrappers add complexity and miss edge cases |
| Syntax highlighting re-synchronization | Trying to preserve attributes while inserting text | 300ms debounce in HighlightingService (already implemented) | Syntax highlighting observer already watches textStorage changes; debounce prevents flicker from toolbar actions followed by re-highlighting; trying to sync attributes manually creates race conditions |

**Key insight:** iOS provides well-tested APIs (UITextInput, UndoManager, NSString) for text editing mechanics. Custom implementations of these patterns are high-risk, hard to test, and break on edge cases (emoji, multi-byte characters, rapid interactions). Stick to documented patterns.

## Common Pitfalls

### Pitfall 1: Undo Stack Invalidation via Direct textStorage Modification
**What goes wrong:** Toolbar code modifies `textView.textStorage` directly without registering undo. Result: undo/redo becomes inconsistent; user presses Undo and formatting disappears but text doesn't revert, or undo corrupts the attributed string highlighting.

**Why it happens:** Direct `textStorage.addAttribute()` or text replacement bypasses the UndoManager. The UITextView expects text changes via UITextInput protocol methods, not raw NSTextStorage mutations. Developers often assume undo manager will track any text change—but it won't if you modify textStorage directly.

**How to avoid:**
1. Use only UITextInput methods (insertText, replace) for all text modifications
2. Verify no direct calls to `textStorage.replaceCharacters(in:, with:)` or `textStorage.addAttribute()`
3. Register undo operations BEFORE text modification, not after
4. Test undo/redo for each toolbar action: apply formatting, press Undo, verify text reverts completely

**Warning signs:**
- After toolbar action and undo, text reverts but formatting still shows (or vice versa)
- Undo stack grows unexpectedly (toolbar actions not appearing as separate undo steps)
- Rapid toolbar clicks create weird interleaved undo states

### Pitfall 2: Cursor Position Loss After Text Insertion
**What goes wrong:** Toolbar inserts text (e.g., bold wrapping), but cursor position jumps to end of text or stays in wrong location instead of staying logically at the original selection boundary. This is especially visible with multi-step operations (bold = 2 insertions for markers).

**Why it happens:** NSRange is a linear index (location + length). When you insert at position 10, all subsequent positions shift. If you insert twice without recalculating offsets, the second insertion's position is wrong. Additionally, assigning selectedRange during text modification doesn't always take effect immediately if timing is off.

**How to avoid:**
1. Save selectedRange BEFORE any modification
2. Recalculate offsets accounting for all insertions you're about to make
3. Restore selectedRange AFTER all modifications complete
4. Use atomic grouping (beginUndoGrouping/endUndoGrouping) for multi-step operations
5. Test with selection, no selection, cursor at line start, cursor at EOF

**Warning signs:**
- After toolbar action, cursor jumps to end of document
- Selecting text, applying formatting, selection is lost
- Rapid toolbar clicks leave cursor in random positions
- Text gets inserted in wrong location after formatting

### Pitfall 3: NSRange Off-by-One Errors with Emoji and Multi-Byte Characters
**What goes wrong:** Text contains emoji or zero-width joiners (family emoji 👨‍👩‍👧, skin-tone modifiers 👩🏾, flag combinations 🏳️‍🌈). Toolbar calculates NSRange for insertion, but NSRange uses UTF-16 code units while Swift String uses grapheme clusters. Result: marker inserted in middle of emoji, breaking it visually.

**Example:**
```
Text: "Hello 👨‍👩‍👧 world"
      0      8          (NSString positions, UTF-16)
      0      1          2         (Swift String.count positions, graphemes)

User selects "world" → selectedRange.location = 8 (UTF-16)
If you calculate using String.count, you get 2
Inserting at position from String.count inserts INSIDE emoji
```

**Why it happens:** UITextView.selectedRange returns NSRange (UTF-16 based). Swift String.count returns grapheme clusters. Confusion between the two leads to position mismatches. Emoji with modifiers have multiple UTF-16 units per visual character.

**How to avoid:**
1. Always use NSString for position calculations, never Swift String.count
2. Use NSString.substring(with:), NSString.substring(to:), NSString.substring(from:) to extract text
3. Use NSString.lineRange(for:) to find line boundaries, never String.split(separator:)
4. Test extensively with: ASCII, emoji (simple 😀, complex 👨‍👩‍👧, modifiers 👩🏾), CJK text (中文, 日本語), newline variations (LF vs CRLF)

**Warning signs:**
- Formatting markers appear in wrong place (middle of emoji or CJK)
- Emoji corrupted after toolbar action
- Cursor position off by a few characters after operation
- Tests pass on ASCII but fail on emoji-heavy content

### Pitfall 4: Syntax Highlighting Feedback Loop / Attribute Loss
**What goes wrong:** Toolbar inserts text with markers `**text**`. Syntax highlighting re-scans the document and replaces entire NSAttributedString via `attributedText =` assignment. This can reset selectedRange to 0, lose transient formatting, or cause visual flicker (raw `**text**` visible for 300ms before highlighting applies).

**Why it happens:** HighlightingService.applyMarkdownColors creates a NEW NSAttributedString and assigns it to textView.attributedText. This assignment loses any transient state, resets selection if not guarded, and can trigger textViewDidChange recursion.

**How to avoid:**
1. The existing code ALREADY preserves selection during highlighting (in MarkdownTextEditor.updateUIView). Verify it's never bypassed:
   ```swift
   let selectedRange = tv.selectedRange
   tv.attributedText = HighlightingService.applyMarkdownColors(...)
   tv.selectedRange = selectedRange  // Restore ✓
   ```
2. The existing 300ms debounce in HighlightingService prevents immediate re-highlighting. Don't bypass this.
3. Toolbar actions don't need special handling; the debounce naturally prevents flicker.
4. Test: apply formatting, verify visual appearance after 300ms (should show formatted text, not raw `**text**`)

**Warning signs:**
- Toolbar formatting shows as raw `**text**` for a moment, then syntax highlighting applies (visual flicker)
- Selection resets to position 0 after toolbar action
- Rapid toolbar actions seem to miss some formatting

### Pitfall 5: Line Range Detection Using String.split Instead of NSString.lineRange
**What goes wrong:** Bullet list implementation splits text on `\n` using Swift String.split(separator:). On Windows files with CRLF line endings (`\r\n`), the line detection breaks, leaving dangling `\r` characters or creating malformed bullet points.

**Why it happens:** Swift String.split and String.components(separatedBy:) are naive about line boundaries. NSString.lineRange(for:) handles all line ending variants (LF, CRLF, CR, Unicode line separator) correctly.

**How to avoid:**
1. Use NSString.lineRange(for:) for ALL line-based operations (bullets, table insertion, etc.)
2. Never use String.split(separator: "\n") or String.components(separatedBy: "\n")
3. Test with files that have: LF line endings, CRLF line endings, mixed line endings

**Warning signs:**
- Bullet points have trailing `\r` or double line breaks
- Line-based operations fail on files from Windows editors
- Test on iOS simulator shows correct behavior but real device fails (simulator defaults to LF; device files may have CRLF from external sources)

## Code Examples

Verified patterns from official iOS documentation and project research:

### Keyboard Toolbar Button (Bold Formatting)
```swift
// Source: SwiftUI .toolbar(placement: .keyboard) + UITextInput patterns
// Location: EditorView.swift

struct EditorView: View {
    @State private var textViewCoordinator: MarkdownTextEditor.Coordinator?

    var body: some View {
        MarkdownTextEditor(text: $text)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Button(action: {
                        textViewCoordinator?.applyBold()
                    }) {
                        Image(systemName: "bold")
                            .foregroundColor(.systemBlue)
                    }
                    .accessibilityLabel("Make text bold")

                    // ... more buttons
                }
            }
    }
}
```

### Bold Wrapping with Undo Registration
```swift
// Source: UITextInput + UndoManager pattern from iOS Human Interface Guidelines
// Location: MarkdownTextEditor.Coordinator

func applyBold() {
    guard let textView = self.textView else { return }

    let selectedRange = textView.selectedRange
    let nsString = textView.text as NSString

    if selectedRange.length > 0 {
        let selectedText = nsString.substring(with: selectedRange)
        let wrapped = "**\(selectedText)**"

        // Register undo BEFORE modifying
        textView.undoManager?.beginUndoGrouping()

        let range = UITextRange(selectedRange: selectedRange)
        textView.replace(range, withText: wrapped)

        textView.undoManager?.endUndoGrouping()
        textView.undoManager?.setActionName("Make Bold")

        // Restore selection inside markers
        textView.selectedRange = NSRange(
            location: selectedRange.location + 2,
            length: selectedRange.length
        )
    }

    text = textView.text
}
```

### Bullet List with Line Range Detection
```swift
// Source: NSString.lineRange(for:) from Foundation documentation
// Location: MarkdownTextEditor.Coordinator

func applyBullet() {
    guard let textView = self.textView else { return }

    let selectedRange = textView.selectedRange
    let nsString = textView.text as NSString

    // Find line boundaries (handles LF, CRLF, CR correctly)
    let lineRange = nsString.lineRange(for: selectedRange)
    let lineText = nsString.substring(with: lineRange)

    // Prefix with "- "
    let bulletedLine = "- " + lineText

    textView.undoManager?.beginUndoGrouping()

    let range = UITextRange(selectedRange: lineRange)
    textView.replace(range, withText: bulletedLine)

    textView.undoManager?.endUndoGrouping()
    textView.undoManager?.setActionName("Add Bullet")

    // Preserve cursor relative position
    textView.selectedRange = NSRange(
        location: selectedRange.location + 2,
        length: 0
    )

    text = textView.text
}
```

### Table Insertion
```swift
// Source: UITextInput pattern + custom formatting
// Location: MarkdownTextEditor.Coordinator

func insertTable() {
    guard let textView = self.textView else { return }

    let tableTemplate = """
        | Header 1 | Header 2 | Header 3 |
        |----------|----------|----------|
        | Cell 1   | Cell 2   | Cell 3   |
        """

    textView.undoManager?.beginUndoGrouping()
    textView.insertText(tableTemplate)
    textView.undoManager?.endUndoGrouping()
    textView.undoManager?.setActionName("Insert Table")

    // Position cursor at first cell
    let insertionPoint = textView.selectedRange.location
    textView.selectedRange = NSRange(
        location: insertionPoint - tableTemplate.count + 20,  // Adjust for first cell
        length: 8  // "Header 1" length
    )

    text = textView.text
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| inputAccessoryView + UITextViewController | SwiftUI .toolbar(placement: .keyboard) + UIViewRepresentable | iOS 15 (2021) | Modern approach is simpler, cleaner; legacy approach requires UIKit bridging complexity |
| Direct textStorage modification | UITextInput protocol (insertText, replace) | iOS 3 (2008) | UITextInput is documented standard; bypassing it breaks undo/redo and performance optimization |
| Manual string position tracking | NSString.lineRange, NSString.substring | iOS 2 (2008) | Prevents emoji corruption; NSString is UTF-16 aware; Swift String is grapheme-cluster aware |
| Custom undo stacks | UndoManager (built-in) | iOS 2 (2008) | System undo integrates with keyboard shortcuts, undo gestures, menu; custom stacks duplicate complexity |

**Deprecated/outdated:**
- **inputAccessoryView:** Legacy UIKit approach for keyboard accessories. SwiftUI `.toolbar(placement: .keyboard)` (iOS 15+) is the modern replacement. inputAccessoryView still works but adds unnecessary UIKit interoperability complexity for iOS 16+ projects.
- **Direct NSTextStorage modification:** Bypasses UndoManager and breaks documented iOS text editing patterns. Use UITextInput protocol instead.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (built-in, already in place from Phases 1-3) |
| Config file | None (standard Xcode test bundle) |
| Quick run command | `xcodebuild test -scheme MarkdownEditor -destination 'platform=iOS Simulator,name=iPhone 16' -testPlan FormattingToolbarTests 2>&1 \| grep -E "(Test Suite|PASS|FAIL)"` |
| Full suite command | `xcodebuild test -scheme MarkdownEditor -testPlan FormattingToolbarTests` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TOOL-01 | Toolbar appears when editor gains focus | Integration | `test_ToolbarVisibilityWithKeyboard` in FormattingToolbarTests.swift | ❌ Wave 0 |
| TOOL-01 | Toolbar disappears when keyboard dismissed | Integration | `test_ToolbarHidesWhenKeyboardDismissed` in FormattingToolbarTests.swift | ❌ Wave 0 |
| TOOL-02 | Keyboard dismiss button closes keyboard | Integration | `test_KeyboardDismissButtonResignsFirstResponder` in FormattingToolbarTests.swift | ❌ Wave 0 |
| FMT-01 | Bold wraps selected text in `**markers**` | Unit | `test_BoldWrapSelectedText_ASCII` in FormattingOperationsTests.swift | ❌ Wave 0 |
| FMT-01 | Bold inserts `**text**` when nothing selected | Unit | `test_BoldInsertPlaceholder_NoSelection` in FormattingOperationsTests.swift | ❌ Wave 0 |
| FMT-01 | Bold with emoji doesn't corrupt characters | Unit | `test_BoldWrapSelectedText_WithEmoji` in FormattingOperationsTests.swift | ❌ Wave 0 |
| FMT-02 | Italic wraps selected text in `*markers*` | Unit | `test_ItalicWrapSelectedText_ASCII` in FormattingOperationsTests.swift | ❌ Wave 0 |
| FMT-02 | Italic inserts `*text*` when nothing selected | Unit | `test_ItalicInsertPlaceholder_NoSelection` in FormattingOperationsTests.swift | ❌ Wave 0 |
| FMT-03 | Bullet prefixes current line with `- ` | Unit | `test_BulletPrefixCurrentLine_ASCII` in FormattingOperationsTests.swift | ❌ Wave 0 |
| FMT-03 | Bullet uses NSString.lineRange (handles CRLF) | Unit | `test_BulletPrefixCurrentLine_CRLF` in FormattingOperationsTests.swift | ❌ Wave 0 |
| FMT-03 | Bullet with multi-line selection prefixes all lines | Unit | `test_BulletPrefixMultipleLines_ASCII` in FormattingOperationsTests.swift | ❌ Wave 0 |
| FMT-04 | Table inserts 3×2 template at cursor | Unit | `test_InsertTable_CorrectTemplate` in FormattingOperationsTests.swift | ❌ Wave 0 |
| FMT-04 | Table replaces selected text | Unit | `test_InsertTable_ReplacesSelection` in FormattingOperationsTests.swift | ❌ Wave 0 |
| UNDO-01 | Undo reverts last toolbar formatting action | Unit | `test_UndoRevertsBoldFormatting` in UndoRedoTests.swift | ❌ Wave 0 |
| UNDO-01 | Undo disabled when stack empty | Unit | `test_UndoDisabledWhenStackEmpty` in UndoRedoTests.swift | ❌ Wave 0 |
| UNDO-02 | Redo re-applies formatting after undo | Unit | `test_RedoReappliesBoldFormatting` in UndoRedoTests.swift | ❌ Wave 0 |
| UNDO-02 | Redo disabled when redo stack empty | Unit | `test_RedoDisabledWhenRedoStackEmpty` in UndoRedoTests.swift | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `xcodebuild test -scheme MarkdownEditor -testPlan FormattingToolbarTests -only-testing 'MarkdownEditorTests/FormattingOperationsTests'` (formatting operations only, ~5s)
- **Per wave merge:** Full test suite via CI/CD (`xcodebuild test -scheme MarkdownEditor`) or manually before pushing
- **Phase gate:** All tests green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `FormattingOperationsTests.swift` — Unit tests for bold, italic, bullet, table formatting with ASCII, emoji, CJK, CRLF line endings
- [ ] `UndoRedoTests.swift` — Unit tests for undo/redo stack integration, canUndo/canRedo state observation
- [ ] `UITextInputIntegrationTests.swift` — Integration tests for keyboard toolbar visibility, button interactions, first responder state
- [ ] Test fixtures for: emoji samples (simple 😀, complex 👨‍👩‍👧, skin tone 👩🏾, flags 🏳️‍🌈), CJK text, CRLF line endings
- [ ] Test helper: `XCTestCase` extension for creating mock UITextView with coordinator, simulating tap actions

## Sources

### Primary (HIGH confidence)
- **UITextInput protocol** - Apple Developer Documentation; verified text insertion/replacement methods
- **UndoManager** - Apple Developer Documentation; undo/redo registration patterns
- **SwiftUI .toolbar(placement: .keyboard)** - Apple Developer Documentation; keyboard toolbar placement API (iOS 15+)
- **NSString.lineRange** - Apple Foundation Framework documentation; line boundary detection
- **NSRange + NSString** - Apple Foundation; UTF-16 position calculations

### Secondary (MEDIUM-HIGH confidence)
- [How to add a toolbar to the keyboard - Hacking with Swift](https://www.hackingwithswift.com/quick-start/swiftui/how-to-add-a-toolbar-to-the-keyboard) — SwiftUI keyboard toolbar patterns
- [NSUndoManager - NSHipster](https://nshipster.com/nsundomanager/) — Undo manager registration and grouping
- [UITextView selectedRange save/restore patterns](https://www.programming-books.io/essential/ios/getting-and-setting-the-cursor-position-7729477acddf4aaa8539261a52c5d5ff) — Cursor position preservation
- [NSRange + UTF-16 emoji handling](https://dreamcooder.medium.com/how-to-restrict-emoji-input-and-enforce-character-length-in-swift-with-uitextfield-uitextview-0f584dfa2388) — Emoji corruption prevention

### Tertiary (Project research, MEDIUM confidence)
- `.planning/research/SUMMARY.md` — v1.0 core stack validation + v1.1 toolbar architectural patterns
- `.planning/research/PITFALLS.md` — Critical pitfalls identified during Phase 1-3 research
- `.planning/research/STACK.md` — Detailed technology stack with integration patterns
- `.planning/phases/04-formatting-toolbar/04-UI-SPEC.md` — Visual and interaction contract

## Metadata

**Confidence breakdown:**
- **Standard stack:** HIGH — UITextInput, UndoManager, NSString are stable iOS APIs; SwiftUI .toolbar(placement: .keyboard) is modern standard (iOS 15+, project targets iOS 16+)
- **Architecture patterns:** HIGH — Patterns drawn from Apple documentation and validated through project research phases 1-3
- **Pitfalls:** HIGH — Critical pitfalls well-documented in project research; prevention strategies are clear and testable
- **Code examples:** MEDIUM-HIGH — Examples follow documented iOS patterns; validation through testing will confirm correctness

**Research date:** 2026-03-26
**Valid until:** 2026-04-26 (30 days; iOS APIs are stable, pitfalls well-characterized)
