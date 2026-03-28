# Research Summary: Formatting Toolbar (v1.1)

**Project:** iOS Markdown Editor v1.1 (Formatting Toolbar)
**Researched:** 2026-03-26
**Mode:** Ecosystem research (how formatting toolbars work in iOS markdown editors)
**Overall confidence:** MEDIUM-HIGH

---

## Executive Summary

The formatting toolbar for iOS markdown editors follows a well-established pattern across all major implementations (1Writer, iA Writer, Editorial, MarkText). The toolbar docks above the iOS keyboard using `UITextView.inputAccessoryView` and provides 5-7 buttons for common operations: bold, italic, bullet lists, and undo/redo. Behavior is highly consistent:

- **Bold/italic:** Wrap selected text with `**markers**` or `*markers*`, toggle (remove) if already wrapped, insert at cursor if no selection
- **Bullet list:** Prefix current line with `- `, toggle off if already prefixed
- **Table:** Insert fixed 3×2 template (or customizable in dedicated apps)
- **Undo/redo:** Direct integration with system `UITextView.undoManager` — no custom state needed

The main implementation risks are: cursor position tracking after text mutations, toggle detection for wrapped text, toolbar integration with SwiftUI UIViewRepresentable coordinator pattern, and ensuring all mutations use `textStorage.replaceCharacters(in:with:)` to preserve undo history.

---

## Key Findings

### Stack
- **Toolbar placement:** `UITextView.inputAccessoryView` (iOS standard, supported in iOS 26)
- **Toolbar component:** `UIToolbar` with `UIBarButtonItem` buttons (native iOS; no third-party library needed)
- **Icons:** SF Symbols system icons (`bold`, `italic`, `list.bullet`, `tablecells`, `arrow.uturn.backward`, `arrow.uturn.forward`)
- **Integration:** UIViewRepresentable coordinator pattern (already used in Phase 3 for UITextView)
- **No third-party library required** — everything is standard iOS APIs

### Architecture
- **Toolbar is stateless** — button actions directly call UITextView mutation methods
- **Undo/redo managed by system** — UITextView.undoManager tracks all mutations automatically
- **Button state computed from UITextView state** — undo/redo buttons enable/disable based on `undoManager.canUndo/canRedo`
- **Cursor and selection preserved** — mutations restore cursor position after text changes

### Critical Pitfall: Undo History Loss
Toolbar actions that use direct `attributedText` assignment (instead of `textStorage.replaceCharacters()`) bypass the undoManager. This is the highest-risk bug category. **Must use textStorage mutation APIs exclusively.**

### Feature Ordering
All 6 features (undo, redo, bold, italic, bullet, table) are table stakes for v1.1. No prioritization needed — all ship together. Implementation order: undo/redo first (lowest risk), then bold/italic, then bullet/table.

---

## Implications for Roadmap

### Phase 4 (v1.1): Formatting Toolbar

**Recommended phase structure:**

1. **4.1 — Undo/Redo (Foundational, P0)** — 4 hours
   - Implement undo/redo buttons wired to UITextView.undoManager
   - No custom state needed; system provides everything
   - Validates toolbar integration pattern before other buttons
   - Early win: users get undo/redo immediately

2. **4.2 — Bold/Italic (Table Stakes, P0)** — 8 hours
   - Implement bold button (wrap + toggle detection)
   - Implement italic button (wrap + toggle detection)
   - Test wrap, toggle, insert, and cursor restoration
   - Toggle detection is critical pitfall area; test thoroughly

3. **4.3 — Bullet List (Medium Risk, P0)** — 6 hours
   - Implement bullet toggle on current line
   - Test with indented lines (important edge case)
   - Cursor position tracking required
   - Line boundary detection (use `paragraphRange(for:)`)

4. **4.4 — Table & Finalize (P0)** — 8 hours
   - Implement table template insertion
   - Finalize toolbar layout and button order
   - Comprehensive testing (all features + interactions)
   - Polish: button icons, spacing, light/dark mode

**Total effort:** ~6.5 developer days (26 hours)

**Dependencies on existing work:**
- Phase 3 UIViewRepresentable<UITextView> must be complete and stable
- UITextView auto-save/file saving must be working (Phase 3 prerequisite)
- Keyboard focus management must be solid

### Why This Order

1. **Undo/redo first:** Lowest risk (system API), validates toolbar pattern, high value
2. **Bold/italic second:** Most-used features; wrap/toggle logic is reusable for later headers
3. **Bullet list third:** Medium complexity; depends on toolbar pattern from bold/italic
4. **Table last:** Lowest value relative to scope; finalize after core formatting works

### Research Flags for Phase 4

- **Toolbar UIViewRepresentable coordination:** May need iteration on coordinator pattern. Have documentation ready for button event handling.
- **Cursor position bugs:** Most likely category of bugs. Implement utility function for position tracking early.
- **Toggle detection edge cases:** Test malformed markdown (e.g., `**hello*` with mismatched markers). Define behavior early.
- **Performance with large files:** Table insertion, line detection might have O(n) string traversal. Test with 1MB+ files.

**Standard research needed?** No — emoji placement in buttons is self-evident; formatter behavior is standardized across iOS editors. No competitive ambiguity or ecosystem uncertainty.

---

## Confidence Assessment

| Area | Confidence | Reason |
|------|------------|--------|
| **Stack (UITextView.inputAccessoryView pattern)** | HIGH | Apple Developer Docs verified iOS 26 support; pattern used in all reviewed editors; no deprecated APIs |
| **Bold/italic behavior (wrap + toggle)** | HIGH | Verified in 4 implementations (1Writer, iA Writer, Editorial, MarkText); consistent across all |
| **Bullet list behavior (line prefix)** | MEDIUM-HIGH | Verified in 3 implementations; one pattern variation (indent handling); clear best practice |
| **Table template** | HIGH | Matches PROJECT.md spec; verified in iA Writer; simple insertion, no complexity |
| **Undo/redo (UITextView.undoManager)** | HIGH | Apple Developer Docs; system API; well-documented; no surprises |
| **Pitfalls (cursor tracking, toggle detection)** | MEDIUM-HIGH | Identified via architecture analysis; not directly verified in source code, but are obvious implementation challenges |
| **Effort estimate (6 days)** | MEDIUM | Based on pattern analysis; actual effort depends on UIViewRepresentable coordinator complexity, which is not fully analyzed |

**Why not higher on effort estimate?** Implementation details of SwiftUI-UIKit bridging could add friction. Real estimate might be 4 days or 9 days depending on existing codebase patterns.

---

## Gaps to Address in Phase 4

### Before Starting Implementation

1. **Coordinator pattern review** — Ensure Phase 3's UIViewRepresentable<UITextView> has clean coordinator for receiving button events. If it doesn't, refactoring needed.
2. **Mutation API audit** — Audit Phase 3's auto-save logic. Verify it uses `textStorage.replaceCharacters()` not direct `attributedText` assignment. If wrong, fix before adding toolbar.
3. **Large file testing** — Test Phase 3 with 1MB+ markdown files. Table insertion, line detection might be slow on large files.

### During Implementation

1. **Toggle detection edge cases** — Define behavior for malformed markdown: `**hello*`, `*hello**`, `* hello *` (with spaces). Test each case.
2. **Multi-line selection behavior** — Spec doesn't say what happens if user selects multiple lines and taps bullet. Implement narrow scope: "single line only"; defer batch operations to v1.2.
3. **Cursor restoration after each action** — Test: after bold wrap, after bullet prefix, after table insert. Cursor must return to sensible position.

### After v1.1 Ships

1. **User feedback on table customization** — Does fixed 3×2 template feel limiting? Collect demand signal for v1.2. (Don't implement custom dimensions in v1.1.)
2. **Header buttons demand** — Users ask for H1-H6 buttons? Document for v1.2 planning.
3. **Keyboard shortcuts demand** — Users want Cmd+B, Cmd+I? iPad support planned? Document for v1.2.

---

## Key Recommendations

### Must Do (v1.1 scope)

1. **Use `textStorage.replaceCharacters(in:with:)` exclusively** — This is the only way to preserve undo history. Any direct NSMutableAttributedString or `attributedText` assignment breaks undo.

2. **Implement toggle detection for bold/italic** — Before wrapping selected text, check if it already starts/ends with `**` or `*`. If yes, remove instead of wrap. This prevents double-bolding.

3. **Use `paragraphRange(for:)` for bullet list** — Don't use cursor position to find line boundaries. Use NSString's built-in line detection. This handles indented lines correctly.

4. **Wire buttons to UITextView.undoManager directly** — Don't implement custom undo state. System does it for free. Just call `undoManager.undo()` / `redo()` and enable/disable buttons based on `canUndo` / `canRedo`.

5. **Test cursor position after each action** — Cursor should return to a sensible location after toolbar action, not jump to document end. Write helper function to track position before/after.

### Should Do (quality, not blocking)

1. **Add UI tests for each button** — Test wrap, toggle, insert behaviors. Undo/redo. Bullet prefix/toggle. Table insert.

2. **Test with large files** — Run toolbar actions on 1MB+ markdown files. Ensure no freezing.

3. **Dark mode support** — Icons and colors should work in light and dark mode.

### Defer to v1.2+

1. Header buttons (H1-H6)
2. Link/image insertion
3. Code block button
4. Custom table dimensions
5. Keyboard shortcuts
6. Batch operations (multi-line bullet prefix)

---

## Open Questions (Low Priority)

1. **Should undo button show count of available undos?** (e.g., "Undo (3)")
   - Answer: No — iOS standard is just "Undo" button. Keep it simple.

2. **Should table insertion show a dialog to customize?**
   - Answer: No — fixed 3×2 for v1.1. Defer to v1.2 if demand is high.

3. **Should bullet button cycle through marker types?** (-, +, *)
   - Answer: No — use `-` only (most common). Defer to v1.2.

4. **What if user selects across line boundaries and taps bullet?**
   - Answer: Scope to single-line behavior for v1.1. Multi-line is v1.2.

---

## Roadmap Impact

**Why this research matters for roadmap:**

1. **Unblocks v1.1 scope** — No surprises in how formatting toolbars work. All features are table stakes, standardized, well-understood.

2. **Clarifies risks** — Cursor position tracking and undo history preservation are the two main pitfalls. Phase 4 planning can allocate time accordingly.

3. **Reduces scope creep** — Clear anti-features list (headers, links, code blocks, custom tables) prevents "while we're at it" additions.

4. **Validates tech stack** — No third-party libraries needed. Native iOS UIToolbar + UIViewRepresentable. Keeps codebase lean.

5. **Sets up v1.2 planning** — Identified deferreds (headers, batch operations, keyboard shortcuts) become v1.2 candidates if demand exists.

---

## Confidence Checklist

- [x] Domain ecosystem surveyed (4+ iOS editors analyzed)
- [x] Technology stack verified (native APIs only; iOS 26 compatible)
- [x] Behavior patterns standardized (wrap/toggle consistent across editors)
- [x] Implementation pitfalls identified (cursor, undo, toggle detection)
- [x] Dependencies on Phase 3 work documented
- [x] Alternative approaches considered (fixed vs. customizable table; toolbar patterns)
- [x] Source hierarchy followed (Apple Docs > Editor implementations > WebSearch)
- [x] Confidence levels assigned honestly (MEDIUM-HIGH overall)
- [x] Anti-features clearly stated (no scope creep)
- [x] Roadmap implications clear (6.5-day effort, 4 sub-phases, clear ordering)
- [x] Open questions documented (low priority, don't block v1.1)

**Overall: READY for Phase 4 kickoff.**

