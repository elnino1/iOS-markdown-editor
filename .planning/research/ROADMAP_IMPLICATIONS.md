# Roadmap Implications: Formatting Toolbar Architecture

**Research Date:** 2026-03-26
**Milestone:** v1.1 Formatting Toolbar
**Status:** Architecture validated, ready for phase execution

---

## Executive Summary

The formatting toolbar integrates cleanly into the existing architecture with **minimal disruption to current code**. The recommended approach uses `inputAccessoryView` (Apple's official guidance from WWDC23) to dock the toolbar above the keyboard, with a new `FormattingService` handling text mutations and the existing `Coordinator` dispatching commands.

**Key outcomes:**
- ✅ No changes to EditorView, AppState, MarkdownDocument, or HighlightingService
- ✅ UITextView's built-in undoManager handles undo/redo automatically
- ✅ Auto-save mechanism continues to work without modification
- ✅ Syntax highlighting applies after mutations (no interaction issues)

---

## Recommended Phase Structure

### Phase 1: FormattingService Implementation (1 day)

**Objective:** Implement pure text mutation logic, testable in isolation.

**Deliverables:**
- `FormattingService.swift` with methods:
  - `applyBold(to textView: UITextView)`
  - `applyItalic(to textView: UITextView)`
  - `applyBulletList(to textView: UITextView)`
  - `insertTable(columns:rows:into:)`
  - `undo(in:)` and `redo(in:)`
  - Helper: `getLineRange(containing:in:)`

- Unit tests for each operation:
  - Bold wrapping with selection
  - Bold insertion at cursor (no selection)
  - Italic wrapping
  - Bullet list prepending to current line
  - Table insertion
  - Undo/redo dispatch to undoManager

**Why first:** Separates business logic from UI. Can test without UITextView lifecycle concerns.

**Estimated effort:** 4-6 hours
- Text manipulation logic: 2-3 hours
- Unit tests: 2-3 hours

---

### Phase 2: FormattingToolbar UI (0.5 day)

**Objective:** Build SwiftUI toolbar component, independent of integration.

**Deliverables:**
- `FormattingToolbar.swift`:
  - `FormattingCommand` enum (bold, italic, bulletList, insertTable, undo, redo)
  - SwiftUI View with HStack of buttons
  - `onFormat: (FormattingCommand) -> Void` closure
  - System images for each button (SF Symbols)
  - Appropriate spacing and styling

- SwiftUI preview for design validation

**Why second:** Can be designed and previewed independently. No dependency on UITextView reference passing.

**Estimated effort:** 2-3 hours
- UI layout and styling: 1.5 hours
- Preview testing: 0.5-1 hour

---

### Phase 3: MarkdownTextEditor Integration (0.5 day)

**Objective:** Attach toolbar to UITextView as inputAccessoryView, wire Coordinator handler.

**Deliverables:**
- Modify `MarkdownTextEditor.swift`:
  - Add `FormattingCommand` enum (import or re-define locally)
  - Modify `makeUIView()`:
    - Create `UIHostingController(rootView: FormattingToolbar { ... })`
    - Set frame to standard toolbar height (44pt)
    - Attach to `textView.inputAccessoryView`
  - Add `Coordinator.handleFormattingCommand()` method:
    - Switch on command type
    - Call corresponding `FormattingService` method
    - Update binding: `self.text = textView.text`

**Integration checklist:**
- [ ] Toolbar appears when keyboard shows
- [ ] Toolbar dismisses with keyboard
- [ ] All buttons dispatch correct commands
- [ ] Binding updates trigger highlighting and save

**Why third:** Depends on both FormattingService and FormattingToolbar being complete.

**Estimated effort:** 2-3 hours
- Integration logic: 1-1.5 hours
- Manual testing in simulator: 1-1.5 hours

---

### Phase 4: Feature Testing & Polish (1 day)

**Objective:** Validate all formatting operations, edge cases, and UX.

**Test scenarios:**
- **Bold/Italic:**
  - Wrap selected text (various lengths)
  - Insert at cursor (no selection)
  - Cursor inside wrapped text
  - Multiple wraps in same line

- **Bullet list:**
  - Bullet first line of file
  - Bullet middle line
  - Bullet last line
  - Already-bulleted line (toggle? or add duplicate?)

- **Table insertion:**
  - Insert at start of file
  - Insert mid-document
  - Replace selection with table

- **Undo/Redo:**
  - Undo single operation
  - Undo multiple operations
  - Redo after undo
  - Redo disabled when at top of stack

- **Highlighting:**
  - Formatting + highlighting both apply correctly
  - Selection preserved after highlighting

- **Auto-save:**
  - Changes saved 1.5s after last operation
  - Unsaved indicator appears/disappears correctly

- **Edge cases:**
  - Empty file → bold → expect `****`
  - Selection spanning multiple lines → bold → expect `**...multiple lines...**`
  - Cursor at start/end of text → bullets → expect prepend/append
  - Large file (>500 KB) → formatting still works (highlighting disabled)

**Estimated effort:** 6-8 hours
- Manual testing: 4 hours
- Bug fixes and refinement: 2-4 hours

---

## Phase Dependencies

```
Phase 1: FormattingService
    ↓ (depends on business logic)
Phase 2: FormattingToolbar
    ↓ (depends on business logic)
Phase 3: MarkdownTextEditor Integration
    ↓ (all three together)
Phase 4: Testing & Polish
```

All phases can proceed sequentially; no parallel tracks needed.

---

## Files Created/Modified

### New Files
- `.planning/research/ARCHITECTURE_TOOLBAR.md` (this architecture reference)
- `MarkdownEditor/FormattingService.swift` (NEW)
- `MarkdownEditor/FormattingToolbar.swift` (NEW)

### Modified Files
- `MarkdownEditor/MarkdownTextEditor.swift` (add toolbar attachment + Coordinator handler)

### Unchanged Files
- `MarkdownEditor/EditorView.swift`
- `MarkdownEditor/AppState.swift`
- `MarkdownEditor/MarkdownDocument.swift`
- `MarkdownEditor/HighlightingService.swift`
- `MarkdownEditor/HomeView.swift`
- All test files

---

## Known Risks & Mitigations

### Risk 1: inputAccessoryView Height / Keyboard Interaction
**Risk:** Toolbar might not size correctly on all devices/orientations.
**Mitigation:** Set fixed height (44pt, standard iOS toolbar height). Test on:
- iPhone 15 (regular)
- iPhone 15 Pro Max (larger)
- iPad (floating keyboard, undocked)

**Phase to validate:** Phase 3–4

---

### Risk 2: Undo Stack Memory Bloat
**Risk:** Undo stack grows unbounded; memory issues in long editing sessions.
**Mitigation:** iOS manages undo stack size reasonably. Document typical file sizes (<500 KB). If needed later, add "Clear Undo History" button in settings.

**Phase to validate:** Phase 4 (test with moderately large file)

---

### Risk 3: Highlighting Interferes with Formatting
**Risk:** After formatting, highlighting re-applies with 300ms debounce; cursor jumps or selection lost.
**Mitigation:** Coordinator.handleFormattingCommand() restores selectedRange after mutation. MarkdownTextEditor.updateUIView() preserves selectedRange during highlighting.

**Phase to validate:** Phase 4 (test bold + immediate keystroke)

---

### Risk 4: Table Insertion Needs Complex Grouping
**Risk:** Multi-step table insertion (insert text + adjust cursor) might create multiple undo entries.
**Mitigation:** Wrap with `undoManager.beginUndoGrouping()` / `endUndoGrouping()`. Validate in unit tests.

**Phase to validate:** Phase 1 (unit test) + Phase 4 (integration test)

---

## Success Criteria

### Phase 1 Success
- [ ] FormattingService.applyBold() test passes (selected text wrapped)
- [ ] FormattingService.applyBold() test passes (cursor position, no selection)
- [ ] FormattingService.applyItalic() test passes
- [ ] FormattingService.applyBulletList() test passes (line handling)
- [ ] FormattingService.insertTable() test passes
- [ ] FormattingService.undo() / redo() dispatch correctly

### Phase 2 Success
- [ ] FormattingToolbar renders in SwiftUI preview
- [ ] All buttons visible and tappable
- [ ] Closure callback fires when buttons tapped
- [ ] Layout responsive on different widths

### Phase 3 Success
- [ ] Toolbar appears above keyboard in simulator
- [ ] Toolbar dismisses with keyboard
- [ ] Button tap → Coordinator.handleFormattingCommand() → FormattingService call
- [ ] Binding updates after formatting (doc.text changes)
- [ ] Auto-save scheduling triggered

### Phase 4 Success
- [ ] Bold wrapping works in editor
- [ ] Italic wrapping works in editor
- [ ] Bullet list prefixing works in editor
- [ ] Table insertion works in editor
- [ ] Undo button reverses last operation
- [ ] Redo button restores after undo
- [ ] Syntax highlighting applies after formatting
- [ ] Unsaved indicator appears/disappears correctly
- [ ] No crashes or hangs in any scenario

---

## Data Validation Before Phase 1

Before starting Phase 1, confirm:

1. **selectedRange API available:** UITextView has `selectedRange: NSRange` property (iOS 16+ ✓)
2. **undoManager available:** UITextView has `undoManager: NSUndoManager?` (iOS standard ✓)
3. **NSString range replacement available:** `(text as NSString).replacingCharacters(in:with:)` (Foundation standard ✓)

All APIs are stable; no blockers.

---

## Post-v1.1 Considerations

**For v1.2 or later:**
- Add more formatting commands (headers, code blocks, strikethrough, etc.)
- Add keyboard shortcuts (Cmd+B for bold, Cmd+I for italic, etc.)
- Add format/syntax palette or context menu
- Undo/redo history viewer (for long sessions)

**Not in scope for v1.1:**
- Markdown preview / rendered output
- WYSIWYG editing
- Nested list support
- Format templates

---

## Summary: Build Plan

| Phase | Duration | Effort | Risk | Blocker? |
|-------|----------|--------|------|----------|
| 1: FormattingService | 1 day | Medium | Low | No |
| 2: FormattingToolbar | 0.5 day | Low | Low | No |
| 3: Integration | 0.5 day | Low | Medium | No |
| 4: Testing | 1 day | High | Medium | No |
| **Total** | **3 days** | **Medium-High** | **Medium** | **No** |

**Go/no-go for Phase 1:** ✅ PROCEED — architecture validated, no blockers, clear implementation path.

---

*Roadmap implications for v1.1 Formatting Toolbar*
*Generated: 2026-03-26*
