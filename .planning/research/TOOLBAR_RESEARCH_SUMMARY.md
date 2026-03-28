# Formatting Toolbar Research Summary

**Milestone:** v1.1 Formatting Toolbar Feature
**Researched:** 2026-03-26
**Status:** Research complete — ready for phase execution

---

## Executive Summary

The formatting toolbar feature requires no new external dependencies and integrates cleanly into the existing SwiftUI + UIViewRepresentable + UITextView architecture. Use SwiftUI's native `.toolbar(placement: .keyboard)` API (iOS 15+) for the toolbar presentation, UITextView's selection APIs for text manipulation, and careful UndoManager registration for undo/redo support.

**Key constraint:** Always register undo BEFORE modifying text. This is the most common implementation pitfall.

**Expected effort:** Low-to-medium complexity. No architectural changes; straightforward API usage.

---

## What This Means for the Phase

### Build Path

1. **Add toolbar UI to SwiftUI view** (30 min)
   - Apply `.toolbar(placement: .keyboard)` modifier
   - Define button actions (applyBold, applyItalic, etc.)

2. **Implement text manipulation in Coordinator** (2-3 hours)
   - Add formatting methods (applyBold, applyItalic, applyBullet, insertTable)
   - Use UITextView.selectedRange and UITextInput methods
   - Register undo for each operation

3. **Wire undo/redo buttons** (30 min)
   - Call textView.undoManager?.undo()/redo()
   - Bind button disabled state to canUndo/canRedo

4. **Test and iterate** (2-3 hours)
   - Test wrapping with selection vs no selection
   - Test undo behavior for each operation
   - Test edge cases (empty selection, line boundaries, etc.)

**Estimated phase duration:** 1-2 days of focused development

### What Does NOT Need to Change

- SwiftUI view hierarchy: No refactoring needed
- UIDocument file I/O: Not affected
- RecentFilesStore: Not affected
- NSAttributedString syntax highlighting: Works automatically with UITextInput
- Error handling: No new error cases introduced

### What Will Be Added

- **New Coordinator methods:** `applyBold()`, `applyItalic()`, `applyBullet()`, `insertTable()`, `undo()`, `redo()`
- **Toolbar UI:** SwiftUI toolbar modifier with 5-6 buttons
- **UndoManager hooks:** registerUndo calls before each text modification

### No Hard Blockers

- All required APIs are stable and documented
- No version compatibility issues (iOS 16+ supports all needed APIs)
- No external package dependencies
- Existing UITextView integration fully compatible

---

## Key Technical Decisions

### Decision 1: SwiftUI `.toolbar` vs UIKit inputAccessoryView

**Chosen:** SwiftUI `.toolbar(placement: .keyboard)`

**Rationale:**
- Project targets iOS 16+, which fully supports SwiftUI's keyboard toolbar API
- Simpler than UIKit inputAccessoryView bridging
- Automatic keyboard appearance/dismissal animations
- No UIKit interoperability needed
- Cleaner code; native to SwiftUI

**Alternative considered:** UIKit inputAccessoryView
- Only use if iOS <15 support required (not this project)
- Adds complexity via UIViewRepresentable bridging

### Decision 2: UITextInput Methods vs Direct textStorage Manipulation

**Chosen:** UITextInput methods (insertText, replace)

**Rationale:**
- Integrates with UndoManager automatically
- Respects the UITextInput protocol contract
- Works with existing syntax highlighting observer
- Standard approach across iOS development

**Alternative considered:** Direct textStorage.replaceCharacters(in:)
- Bypasses UndoManager; undo won't work
- May break syntax highlighting observer
- Not recommended by Apple

### Decision 3: Manual Undo Registration vs Grouping

**Chosen:** Individual registerUndo for each button action

**Rationale:**
- Each toolbar button = one logical user action
- Simple to implement and understand
- One tap = one undo entry (good UX)
- Covers all formatting operations

**Alternative considered:** Undo grouping (beginUndoGrouping/endUndoGrouping)
- Use only if one button tap = multiple internal operations
- Not needed for this feature (each button is atomic)

---

## Implementation Checklist for Phase

### Core Functionality
- [ ] Add `.toolbar` modifier to editor view with ToolbarItemGroup
- [ ] Implement `applyBold()` method (wrap or insert markers)
- [ ] Implement `applyItalic()` method (wrap or insert markers)
- [ ] Implement `applyBullet()` method (prefix current line with "- ")
- [ ] Implement `insertTable()` method (insert 3x2 table template)
- [ ] Implement `undo()` method (call textView.undoManager?.undo())
- [ ] Implement `redo()` method (call textView.undoManager?.redo())

### Undo/Redo Wiring
- [ ] Register undo BEFORE text modification in each method
- [ ] Bind undo/redo button disabled state to canUndo/canRedo
- [ ] Verify undo stack works correctly for each operation

### Testing
- [ ] Test bold: with selection, without selection
- [ ] Test italic: with selection, without selection
- [ ] Test bullet: at line start, mid-line, multiple lines
- [ ] Test table: at cursor position, verify formatting
- [ ] Test undo: each operation undoes correctly
- [ ] Test redo: undo followed by redo works
- [ ] Test edge cases: empty file, single character, multiline selection

### Integration
- [ ] Verify syntax highlighting still works after formatting
- [ ] Verify file changes detected (dirty flag still works)
- [ ] Verify save still works (UIDocument coordination)
- [ ] Verify no crashes with large files

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|-----------|
| Incorrect undo behavior | Medium | High | Careful testing; verify undo registration happens first |
| selectedRange/selectedTextRange confusion | Medium | Medium | Clear variable names; conversion comments in code |
| Syntax highlighting breaks | Low | High | Test after each formatting operation; verify observer fires |
| Complex edge cases (line boundaries, multi-selection) | Medium | Medium | Test-driven development; start with simple cases |
| Performance degradation on large files | Low | Medium | Monitor during testing; use Coordinator pattern (already in place) |

---

## What NOT to Do

1. **Don't modify textStorage directly** — Use UITextInput methods
2. **Don't register undo after text change** — Always register first
3. **Don't mix NSRange and UITextRange** — Keep types clear
4. **Don't add external dependencies** — Everything is built-in
5. **Don't use inputAccessoryView** — Use SwiftUI toolbar instead
6. **Don't skip undo registration** — Every text modification needs it

---

## Phase Success Criteria

✓ **Functional:**
- All toolbar buttons insert/wrap text correctly
- Undo/redo work for all operations
- No crashes or hangs

✓ **Integration:**
- Syntax highlighting preserved
- File dirty flag still works
- Save/load unaffected

✓ **Code Quality:**
- Clear method names describing what formatting is applied
- UndoManager registration consistent across all methods
- Comments explaining the registration-before-modification pattern

✓ **Testing:**
- All 7 button actions tested individually
- Undo/redo tested for each action
- Edge cases handled (empty selection, line boundaries)

---

## Open Questions for Phase Execution

1. **Keyboard dismissal:** Should the keyboard close after a toolbar button tap? (Current: stays open. UX decision needed.)
2. **Button styling:** How should toolbar buttons appear? (Text labels, SF Symbols, custom icons?)
3. **Button layout:** Should buttons be scrollable or fit in one line? (Depends on screen size/button count.)
4. **Cursor positioning:** After wrapping text, where should cursor go? (Default: after closing marker. Alternative: select wrapped text.)
5. **Line counting for bullets:** Handle bullet prefixing for multiple selected lines? (Phase 1.1: single line only. Phase 2: multiple?)

**Recommendation:** Make quick UX decisions early in phase; defer complex multi-line operations to Phase 2.

---

## Sources

All research sourced from:
- Official Apple Developer Documentation (UITextView, UITextInput, UndoManager, SwiftUI.toolbar)
- Apple Developer Forums (UIViewRepresentable integration patterns)
- Hacking with Swift (tutorial-style explanations with code examples)

See STACK.md for complete source list.

---

*Last updated: 2026-03-26*
