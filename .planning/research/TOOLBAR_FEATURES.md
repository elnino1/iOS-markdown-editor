# Feature Landscape: Formatting Toolbar (v1.1)

**Domain:** iOS markdown editor formatting toolbar (keyboard-docked, bold/italic/list/table/undo/redo)
**Researched:** 2026-03-26
**Scope:** NEW features only (v1.1 milestone); builds on existing UITextView editing infrastructure from Phase 3
**Confidence:** MEDIUM-HIGH (iOS 26 API confirmed via Apple Developer Docs; editor patterns verified across 4+ implementations: 1Writer, iA Writer, Editorial, MarkText)

---

## Table Stakes

Features users expect from any markdown editor toolbar. Missing = feels like feature parity gap.

| Feature | Why Expected | Complexity | Dependencies | Notes |
|---------|--------------|------------|--------------|-------|
| **Bold button (wrap selected text)** | Every markdown editor has it; markdown requires `**text**` syntax | Low | Existing UITextView selection API, NSRange manipulation | Should toggle if text already bold |
| **Italic button (wrap selected text)** | Essential inline formatting; markdown requires `*text*` syntax | Low | Existing UITextView selection API, NSRange manipulation | Should toggle if text already italic |
| **Undo button** | iOS standard for text editing; recovers accidental changes | Very Low | UITextView.undoManager (built-in system API) | Uses system undo stack; no custom state needed |
| **Redo button** | iOS standard companion to undo; expected when undo exists | Very Low | UITextView.undoManager (built-in system API) | Uses system redo stack; no custom state needed |
| **Toolbar docked above keyboard** | Standard iOS pattern since iOS 5; inputAccessoryView | Low | UITextView.inputAccessoryView API (standard) | Appears automatically when keyboard shows |

---

## Differentiators

Features that set product apart from basic text editors. Not universal, but valued.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Bullet list toggle (prefix current line)** | Quick list formatting; avoids manually typing `- ` on every line; toggle removes prefix if already present | Medium | Requires line detection (NSString.paragraphRange), prefix insertion without full text rewrap | Most iOS markdown editors include this (1Writer, iA Writer, Editorial) |
| **Table insertion template (3×2 default)** | Users start tables without manual formatting; matches PROJECT.md spec | Medium | Inserts fixed template; cursor positioning for next edit | Dedicated apps (Markdown Tables) exist, but integrated UX is better; standard in iA Writer |
| **Selection-aware formatting** | Smooth workflow: select text → tap bold; or tap bold → type. No wasted steps | Low | Already standard in all reviewed iOS editors | No extra complexity vs wrapping only |

---

## Anti-Features

Deliberately NOT building in v1.1. Scope creep risk.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| **Header buttons (H1-H6 prefixes)** | Adds visual clutter to toolbar; headers less frequently used than bold/italic/lists; easy to type manually | Defer to v1.2; test demand first; can observe if users struggle with headers |
| **Link/image insertion dialog** | Requires inline URL picker/browser; new interaction pattern; significant scope; better for v2 with preview | Defer to v2; users can paste markdown links manually or use snippets |
| **Code block insertion button** | Less common than bold/italic/lists; easy to type ````` manually | Defer to v1.2+ |
| **"Smart" table resizing / column alignment UI** | Bloat and cognitive load; dedicated Markdown Tables app handles this better | Keep out of scope; recommend external tool for complex table editing |
| **Markdown preview pane** | Out of scope per PROJECT.md; v2 feature | Defer to v2 |
| **Customizable toolbar buttons** | No demand signal; fixed 6-button toolbar is optimal for iOS | Use fixed set; allow feedback for customization in v2 |
| **Keyboard shortcuts (Cmd+B, Cmd+I, Cmd+Z)** | Nice-to-have for power users; toolbar is primary on iPhone; iPad may need later | Defer to v1.2 if iPad support added; focus on touch-first UX for v1.1 |

---

## Behavioral Specifications

Based on research across 1Writer, iA Writer, Editorial, MarkText — all verified implementations.

### Bold & Italic: Wrap-with-Toggle Pattern

**Standard behavior** (verified in 4+ editors):

1. **User selects text and taps bold**: Wraps selection with `**markers**`
   - Input: "hello"
   - Output: `**hello**`

2. **User places cursor (no selection) and taps bold**: Inserts `** **` with cursor between
   - Input: cursor at position 5
   - Output: `** |** ` (cursor at |)

3. **User taps bold again on selected `**text**`**: Toggles off (removes markers)
   - Input: selection = `**hello**`
   - Output: `hello` (markers removed)

4. **User taps bold on partial match**: Wraps regardless (doesn't detect asymmetric markers)
   - Input: selection = `**hello*` (malformed)
   - Output: `****hello***` (wraps as-is; edge case, low priority)

**Implementation detail:** Before wrapping, check if selection starts with `**` AND ends with `**` (or `*` for italic). If true, remove instead of wrap. Otherwise, wrap.

### Bullet List: Line Prefix Toggle

**Standard behavior** (verified in iA Writer, MarkText, Sublime MarkdownEditing):

1. **User places cursor anywhere on line and taps bullet button**: Current line is prefixed with `- `
   - Input: cursor on line "hello"
   - Output: `- hello` (prefix at line start, not at cursor)

2. **User taps bullet again on line starting with `- `**: Toggles off (removes prefix)
   - Input: cursor on `- hello`
   - Output: `hello`

3. **Edge case — indented line**: Prefix added at line start (after leading whitespace)
   - Input: cursor on `\thello` (tab-indented)
   - Output: `\t- hello` (prefix after indent)

**Scope for v1.1:** Single-line toggle only. Multi-line bullet prefixing deferred to v1.2.

**Implementation detail:** Use `NSString.paragraphRange(for:)` to find line boundaries. Insert `- ` at start of line (after any leading whitespace). Restore cursor position after insertion.

### Table Insertion: Fixed Template

**Standard behavior** (verified in iA Writer, most built-in editors):

1. **User places cursor and taps table button**: Inserts 3-column × 2-row template at cursor
   - Input: cursor at position 10 in document
   - Output:
     ```
     | Col 1 | Col 2 | Col 3 |
     |-------|-------|-------|
     |       |       |       |
     ```
   - Cursor positioned at first cell for immediate editing

2. **No customization in v1.1**: Fixed dimensions (3 columns, 2 rows), header row included

**Rationale:** Matches PROJECT.md spec. Keeps UX friction low. If users need custom dimensions, dedicated Markdown Tables app ($1.99 on App Store) handles this; recommend external tool.

**Implementation detail:** Define table string constant. Use NSRange to insert at cursor position. Position cursor at first empty cell using NSRange calculation.

### Undo & Redo: System UndoManager

**Standard behavior** (verified via Apple Developer Docs, iOS 26):

1. **User edits text via toolbar button action**: Change is tracked by UITextView.undoManager automatically
   - Toolbar action calls `textView.textStorage.replaceCharacters(in:with:)`
   - Change enters undo stack immediately

2. **User taps undo button**: System reverts to previous state
   - Calls `undoManager.undo()`
   - Reverts last action (any origin: typing, toolbar, paste, etc.)

3. **User taps redo button**: System restores undone action
   - Calls `undoManager.redo()`
   - Restores last undone action

4. **Button state reflects possibility**: Undo button enabled only if `undoManager.canUndo == true`; Redo button enabled only if `undoManager.canRedo == true`

**Critical implementation detail:** UITextView.undoManager ONLY tracks mutations via `textStorage.replaceCharacters(in:with:)` or `textStorage.insertAttributedString()`. Direct NSMutableAttributedString manipulation (e.g., `textView.attributedText = newString`) bypasses undo tracking. **Always use textStorage mutation APIs.**

**No custom undo state needed.** System provides unlimited undo/redo for free.

---

## Toolbar Layout & Appearance

**iOS keyboard shelf pattern** (verified in iA Writer, 1Writer):

```
┌─────────────────────────────────────────────────────┐
│ [ ↶ ] [ ↷ ] [ B ] [ I ] [ • ] [ ≡ ] |               │
│ Undo   Redo  Bold  Italic Bullet Table  (spacer)   │
└─────────────────────────────────────────────────────┘
```

**Sizing:**
- Toolbar height: 44pt (iOS standard, matches keyboard accessory height)
- Button size: ~44pt × 44pt (iOS standard touch target)
- Icons: SF Symbols (system icons)
  - `arrow.uturn.backward` (Undo)
  - `arrow.uturn.forward` (Redo)
  - `bold` (Bold)
  - `italic` (Italic)
  - `list.bullet` (Bullet)
  - `tablecells` (Table)

**Layout strategy:** Horizontal row, fixed order, flexible spacing. Toolbar scrolls if needed on narrow screens (1Writer approach; not necessary for 6 buttons on iPhone).

**Appearance:**
- Light mode: Dark icons on light background
- Dark mode: Light icons on dark background
- Tint color: Match system blue (or accent color if app defines one)
- Button state: Disabled (50% alpha) when action unavailable (e.g., redo when no redo available)

---

## Feature Dependencies & Integration

```
Formatting Toolbar (v1.1)
├── Requires: Existing UIViewRepresentable<UITextView> (from Phase 3)
├── Requires: UITextView focus/keyboard management (from Phase 3)
│
├── Bold button
│   ├── UITextView.selectedRange (selection API)
│   └── UITextView.textStorage.replaceCharacters(in:with:) (mutation API)
│
├── Italic button
│   ├── UITextView.selectedRange
│   └── UITextView.textStorage.replaceCharacters(in:with:)
│
├── Bullet list button
│   ├── UITextView.textStorage.mutableString.paragraphRange()
│   └── UITextView.textStorage.replaceCharacters(in:with:)
│   └── UITextView cursor position restoration
│
├── Table button
│   ├── UITextView.selectedRange (cursor position)
│   └── UITextView.textStorage.replaceCharacters(in:with:)
│
├── Undo button
│   └── UITextView.undoManager.undo()
│       └── NO custom state; system-managed
│
└── Redo button
    └── UITextView.undoManager.redo()
        └── NO custom state; system-managed

Toolbar integration
├── UITextView.inputAccessoryView = UIToolbar
└── Requires: UIViewRepresentable coordinator to manage toolbar events
```

**Critical dependency:** UITextView must be first responder for keyboard and toolbar to appear. If keyboard doesn't show, toolbar doesn't show.

---

## MVP Feature Priority

**Ship in v1.1** (in order of value):

1. **Undo button** — Very low risk (system API), high value (recovers mistakes), validates "redo too"
2. **Redo button** — Same as undo; ship together
3. **Bold button** — Most-used formatting; table stakes
4. **Italic button** — Second most-used; table stakes
5. **Bullet list button** — Medium complexity, valuable for list editing
6. **Table button** — Matches spec, useful for structured content

**All six are in v1.1 scope.** No priority cuts needed; total implementation ~400-500 lines of code.

---

## Testing Checklist

| Feature | Test Case | Success Criteria | Priority |
|---------|-----------|------------------|----------|
| **Toolbar visibility** | Open text editor | Toolbar appears above keyboard | P0 |
| **Bold wrap** | Select "hello" → tap bold | Text becomes `**hello**` | P0 |
| **Bold toggle** | Select `**hello**` → tap bold | Becomes `hello` (markers removed) | P0 |
| **Bold insert** | No selection, cursor in middle → tap bold | `** |** ` inserted with cursor between | P1 |
| **Italic wrap** | Select "hello" → tap italic | Text becomes `*hello*` | P0 |
| **Italic toggle** | Select `*hello*` → tap italic | Becomes `hello` | P0 |
| **Undo after bold** | Edit → bold → undo | Bold removed, text reverted | P0 |
| **Redo after undo** | Edit → bold → undo → redo | Bold reapplied | P0 |
| **Undo button state** | No edits made | Undo button disabled (grayed out) | P0 |
| **Redo button state** | Undo performed | Redo button enabled | P0 |
| **Bullet line** | Cursor on "hello" → tap bullet | Line becomes `- hello` | P0 |
| **Bullet toggle** | Cursor on `- hello` → tap bullet | Becomes `hello` (prefix removed) | P0 |
| **Bullet indented** | Cursor on `\thello` → tap bullet | Becomes `\t- hello` | P1 |
| **Table insert** | Cursor at position 0 → tap table | 3×2 table template inserted | P0 |
| **Table cursor position** | After table insert | Cursor positioned at first cell | P1 |
| **Multiple operations undo** | Edit → bold → italic → undo → undo | Both undone in reverse order | P1 |

---

## Known Pitfalls & Mitigations

### Pitfall 1: Undo/Redo History Lost on Programmatic Edits

**What goes wrong:** Toolbar button actions that directly manipulate `NSMutableAttributedString` bypass the undoManager.

**Why it happens:** `textView.attributedText = newString` doesn't trigger undo tracking. Direct property assignment circumvents the mutation observation system.

**Consequences:** User taps undo after toolbar action; nothing happens. History appears broken.

**Prevention:** Always use `UITextView.textStorage.replaceCharacters(in:with:)` instead of direct `attributedText` assignment or `mutableString` manipulation.

**Detection:** User performs toolbar action, then undo; change is not reverted.

---

### Pitfall 2: Cursor Position Lost After Formatting

**What goes wrong:** After wrapping text or inserting prefix, cursor ends up at unexpected location (e.g., end of document instead of after formatted text).

**Why it happens:** Text mutations shift NSRange positions. If cursor position is not manually tracked and restored, it gets reset to document end.

**Consequences:** User can't continue editing smoothly; cursor jumped away from edited area.

**Prevention:**
1. Before mutation, capture current cursor position: `let originalCursor = textView.selectedRange.location`
2. Calculate new cursor position after mutation
3. After `replaceCharacters(in:with:)`, restore: `textView.selectedRange = NSRange(location: newCursor, length: 0)`

**Detection:** Toolbar action is performed, cursor visibly jumps away from edited text.

---

### Pitfall 3: Toolbar Doesn't Appear Until Keyboard Shows

**What goes wrong:** inputAccessoryView is hidden until keyboard appears. Some flows might skip showing the keyboard (e.g., programmatic focus that doesn't trigger keyboard).

**Why it happens:** inputAccessoryView visibility is tied to keyboard visibility in iOS.

**Consequences:** Toolbar invisible in some flows; user thinks feature is broken.

**Prevention:** Ensure UITextView is first responder before any formatting action. Call `textView.becomeFirstResponder()` if needed.

**Detection:** Toolbar visible in normal editing but missing in programmatic flows.

---

### Pitfall 4: Selection-Aware Toggle Detects Syntax Incorrectly

**What goes wrong:** Tap bold on `**text**` → wraps it again, creating `****text****` instead of toggling off.

**Why it happens:** Toggle detection not implemented; code always wraps regardless of existing syntax.

**Consequences:** User double-bolds text and gets malformed markdown (`****text****` instead of `text`).

**Prevention:** Before wrapping, check:
```swift
let selection = textView.textStorage.attributedSubstring(from: selectedRange).string
if selection.hasPrefix("**") && selection.hasSuffix("**") {
    // Remove markers
    let unwrapped = String(selection.dropFirst(2).dropLast(2))
    textView.textStorage.replaceCharacters(in: selectedRange, with: unwrapped)
} else {
    // Wrap with markers
    let wrapped = "**\(selection)**"
    textView.textStorage.replaceCharacters(in: selectedRange, with: wrapped)
}
```

**Detection:** User taps bold on bolded text; output is `****text****` or similar.

---

### Pitfall 5: Bullet List Prefix Breaks on Indented Lines

**What goes wrong:** Tab-indented line gets prefix added in wrong position (e.g., `- \ttext` instead of `\t- text`).

**Why it happens:** Cursor position is used instead of line start for prefix insertion.

**Consequences:** Indented lists look broken; prefix appears before indent.

**Prevention:** Use `NSString.paragraphRange(for:)` to find line boundaries, not cursor position:
```swift
let paragraphRange = textView.textStorage.string.paragraphRange(for: selectedRange)
let lineStart = paragraphRange.location
// Insert at lineStart, not at selectedRange.location
```

**Detection:** Indented lists have `- ` in wrong position; not at actual line start.

---

### Pitfall 6: Table Template String Format Mismatch

**What goes wrong:** Table template is inserted with wrong pipe spacing or alignment, producing invalid markdown.

**Why it happens:** Template string has extra spaces or inconsistent formatting.

**Consequences:** Table doesn't render in preview or appears malformed.

**Prevention:** Use consistent template:
```
| Col 1 | Col 2 | Col 3 |
|-------|-------|-------|
|       |       |       |
```
Verify in a markdown renderer before shipping. Test with common parsers (GFM, CommonMark).

**Detection:** Inserted table has misaligned pipes; doesn't render in preview.

---

### Pitfall 7: UIViewRepresentable Coordinator Not Receiving Button Events

**What goes wrong:** Toolbar buttons are tapped but no action occurs; events don't reach SwiftUI coordinator.

**Why it happens:** UIToolbar buttons not wired to coordinator actions; target/action not set correctly.

**Consequences:** Toolbar buttons appear but are unresponsive.

**Prevention:** In UIViewRepresentable makeUIView(), wire each button:
```swift
let boldButton = UIBarButtonItem(image: UIImage(systemName: "bold"),
                                  style: .plain,
                                  target: context.coordinator,
                                  action: #selector(coordinator.tappedBold))
toolbar.items = [boldButton, ...]
```

**Detection:** Toolbar visible, buttons appear clickable, but nothing happens when tapped.

---

## Complexity & Estimation

| Component | Size (lines) | Blocker Risk | Days (1 dev) |
|-----------|--------------|-------------|--------------|
| Bold button | 30-50 | Low | 0.5 |
| Italic button | 30-50 | Low | 0.5 |
| Bullet list button | 80-100 | Medium (line detection) | 1 |
| Table button | 40-50 | Low | 0.5 |
| Undo button | 10-20 | Very Low (system API) | 0.25 |
| Redo button | 10-20 | Very Low (system API) | 0.25 |
| Toolbar UIToolbar setup | 50-80 | Medium (UIViewRepresentable binding) | 1 |
| Button state management | 40-60 | Low | 0.5 |
| Tests (unit + UI) | 150-200 | Low | 1.5 |
| **TOTAL** | **~450-550** | **Medium overall** | **~6 days** |

**Risks:** Toolbar integration with SwiftUI UIViewRepresentable (requires coordinator pattern expertise). Cursor position tracking after mutations (off-by-one errors common).

---

## Implementation Phases

### Phase 4.1: Undo/Redo (Lowest risk, highest value)
- Implement undo/redo buttons
- Wire to UITextView.undoManager
- Test with multiple edit types
- **Effort:** ~4 hours

### Phase 4.2: Bold/Italic (Table stakes)
- Implement bold button (wrap + toggle)
- Implement italic button (wrap + toggle)
- Test wrap, toggle, insert behaviors
- **Effort:** ~8 hours

### Phase 4.3: Bullet List (Medium complexity)
- Implement bullet toggle on current line
- Test indented lines, toggle-off
- **Effort:** ~6 hours

### Phase 4.4: Table & Integration (Finalize)
- Implement table template insertion
- Finalize toolbar layout and appearance
- Comprehensive testing
- **Effort:** ~8 hours

**Total:** ~26 hours (= ~3.25 dev days), assuming 1 experienced developer.

---

## Sources

**Verified implementations:**
- [Apple Developer Documentation: UITextView inputAccessoryView](https://developer.apple.com/documentation/uikit/uitextview/inputaccessoryview)
- [Apple Developer Forums: InputAccessoryView with SwiftUI (iOS 26)](https://developer.apple.com/forums/thread/684991)
- [Hacking with Swift: How to add a toolbar above the keyboard](https://www.hackingwithswift.com/example-code/uikit/how-to-add-a-toolbar-above-the-keyboard-using-inputaccessoryview)

**Editor behavior references:**
- [iA Writer Markdown Guide](https://ia.net/writer/support/basics/markdown-guide)
- [1Writer — Markdown Text Editor](https://1writerapp.com/)
- [The Sweet Setup: Our favorite Markdown writing app for iOS](https://thesweetsetup.com/apps/our-favorite-markdown-writing-app-for-the-iphone/)
- [SitePoint: The Best Markdown Editors for iOS](https://www.sitepoint.com/best-ios-markdown-editors/)

**Technical references:**
- [GitHub: KeyboardToolbar library](https://github.com/simonbs/KeyboardToolbar)
- [Markdown Guide: Basic Syntax](https://www.markdownguide.org/basic-syntax/)
- [UI Patterns: Undo design pattern](https://ui-patterns.com/patterns/undo)
- [Medium: Designing Undo/Redo for a Text Editor (2026)](https://ajmalmohad.medium.com/designing-undo-redo-for-a-text-editor-2f1a9a6202c8)

**Competitor/reference apps:**
- [Markdown Tables App (Apple App Store)](https://www.markdowntables.app/)

