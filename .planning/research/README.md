# Formatting Toolbar Integration Research

**Milestone:** v1.1 Formatting Toolbar
**Research Date:** 2026-03-26
**Status:** ✅ Complete — Ready for Phase Execution

---

## Research Files Overview

### 1. **TOOLBAR_INTEGRATION_SUMMARY.md** — START HERE
Quick reference for the entire architecture. Answers:
- How should the toolbar integrate? → inputAccessoryView pattern
- Where does formatting logic live? → FormattingService
- How do we preserve undo/redo? → Mutate textView.text directly
- What changes, what doesn't? → Integration checklist

**Use this:** When you need a quick answer before diving into details.

---

### 2. **ARCHITECTURE_TOOLBAR.md** — DETAILED REFERENCE
Complete architectural documentation:
- System overview diagram (layers, components)
- Component responsibilities table
- Project structure (files, folders, rationale)
- Three key patterns explained with code examples
- Data flow diagrams (toolbar action → display update)
- Anti-patterns to avoid with explanations
- Integration points (files changed/unchanged)
- UITextView reference management explained
- Testing strategy

**Use this:** When designing implementation or reviewing code.

---

### 3. **ROADMAP_IMPLICATIONS.md** — PHASE PLANNING
Phase structure and build order:
- Phase 1: FormattingService (1 day) - text mutation logic
- Phase 2: FormattingToolbar (0.5 day) - SwiftUI UI
- Phase 3: MarkdownTextEditor Integration (0.5 day) - attach toolbar
- Phase 4: Testing & Polish (1 day) - validation

**Use this:** When planning sprints or assigning work.

---

## Quick Facts

| Question | Answer |
|----------|--------|
| **Toolbar positioning?** | Use `inputAccessoryView` (Apple WWDC23 recommendation) |
| **Formatting logic location?** | `FormattingService` (static struct, pure functions) |
| **Undo/redo support?** | Mutate `textView.text` directly (iOS tracks automatically) |
| **New files?** | FormattingService.swift, FormattingToolbar.swift |
| **Modified files?** | MarkdownTextEditor.swift (toolbar attachment + Coordinator handler) |
| **Files that DON'T change?** | EditorView, AppState, MarkdownDocument, HighlightingService, HomeView |
| **Build duration?** | 3 days (Phase 1–4) |
| **Confidence level?** | HIGH (Apple WWDC23 guidance + established patterns) |

---

## Architecture in One Image

```
FormattingToolbar (SwiftUI)
    ↓ (onFormat closure)
Coordinator.handleFormattingCommand()
    ↓ (dispatch)
FormattingService.applyBold()
    ↓ (text mutation)
UITextView.text = newValue
    ↓ (undoManager tracks automatically)
Coordinator.textViewDidChange()
    ↓ (binding update)
EditorView binding setter → doc.text
    ↓ (existing pipeline)
HighlightingService + Auto-save
```

---

## Key Decisions Summary

| Decision | Chosen | Why Not Alternative |
|----------|--------|-------------------|
| **Toolbar positioning** | inputAccessoryView | .toolbar(placement: .keyboard) less flexible; inputAccessoryView gives more control |
| **Where formatting lives** | FormattingService | Not in Coordinator (separation of concerns) or EditorView (wrong layer) |
| **Text mutation method** | textView.text = ... | Not textStorage (bypasses undo) or manual registerUndo (unnecessary) |
| **UITextView reference** | Closure capture | Not @State (can't store UIKit views) or property (lifecycle mismatch) |
| **Undo grouping** | Only for multi-step ops | Simple mutations tracked automatically; no manual grouping needed |

---

## Integration Points

### Files to Create
```
MarkdownEditor/
├── FormattingService.swift      # NEW — text mutation logic
└── FormattingToolbar.swift      # NEW — SwiftUI toolbar UI
```

### Files to Modify
```
MarkdownEditor/
└── MarkdownTextEditor.swift     # MODIFIED — add toolbar attachment + Coordinator handler
```

### Files Unchanged (✓)
```
MarkdownEditor/
├── EditorView.swift             # ✓ No changes needed
├── AppState.swift               # ✓ No changes needed
├── MarkdownDocument.swift       # ✓ No changes needed
├── HighlightingService.swift    # ✓ No changes needed
└── HomeView.swift               # ✓ No changes needed
```

---

## Execution Roadmap

### Phase 1: FormattingService (1 day)
- Create FormattingService.swift
- Implement: applyBold, applyItalic, applyBulletList, insertTable, undo, redo
- Write unit tests
- **No UI integration yet**

### Phase 2: FormattingToolbar (0.5 day)
- Create FormattingToolbar.swift (SwiftUI component)
- Define FormattingCommand enum
- Create buttons with closure callbacks
- Add SwiftUI preview
- **No UITextView reference yet**

### Phase 3: MarkdownTextEditor Integration (0.5 day)
- Modify MarkdownTextEditor.swift
- Create UIHostingController(FormattingToolbar)
- Attach to textView.inputAccessoryView
- Add Coordinator.handleFormattingCommand()
- Manual simulator testing

### Phase 4: Testing & Polish (1 day)
- Test all formatting operations
- Validate undo/redo
- Test edge cases (empty file, large selection, etc.)
- Verify highlighting + auto-save work
- Performance check

---

## Success Criteria

✅ Toolbar appears above keyboard when UITextView is focused
✅ Bold/Italic buttons wrap selected text (or insert at cursor)
✅ Bullet button prefixes line with `- `
✅ Table button inserts markdown table
✅ Undo button reverses last operation
✅ Redo button restores after undo
✅ Syntax highlighting applies after operations
✅ Auto-save triggers on changes
✅ No crashes in edge cases

---

## Known Risks & Mitigations

| Risk | Severity | Mitigation |
|------|----------|-----------|
| Toolbar height incorrect on some devices | Medium | Set fixed 44pt (standard iOS) + test on iPhone/iPad |
| Undo stack memory grows unbounded | Low | Monitor in Phase 4; iOS manages reasonably |
| Highlighting interferes with formatting | Low | Existing debounce (0.3s) prevents race conditions |
| Selection lost after formatting | Low | Coordinator preserves/restores selectedRange |
| Large file (>500 KB) support | Low | Highlighting already disabled; formatting still works |

---

## Official Guidance

**From Apple WWDC23 "Keep up with the keyboard":**
> The keyboard layout guide is the recommended method for handling keyboard adjustments, including toolbars above the keyboard.

Our approach uses `inputAccessoryView` (the standard pattern that works with keyboard layout guide automatically).

**From Apple UIKit Documentation:**
> Setting textView.text triggers the property observer, which registers undo actions automatically.

Our approach mutates `textView.text` directly (not `textStorage`), preserving undo/redo.

---

## No Blockers

✅ All required APIs available (iOS 16+)
✅ No external dependencies
✅ No version compatibility issues
✅ Existing auto-save mechanism works unchanged
✅ Syntax highlighting works unchanged
✅ File I/O unaffected

---

## Frequently Asked Questions

**Q: Why inputAccessoryView instead of .toolbar(placement: .keyboard)?**
A: inputAccessoryView gives more direct control; .toolbar is a SwiftUI wrapper around it. Since we're already using UIViewRepresentable, inputAccessoryView is simpler.

**Q: What if the toolbar is too short or too tall?**
A: Set the frame explicitly: `toolbar.view.frame = CGRect(x: 0, y: 0, width: width, height: height)`. Standard is 44pt.

**Q: Will undo/redo work correctly?**
A: Yes. UITextView.undoManager tracks `textView.text` mutations automatically. No manual registration needed for simple operations.

**Q: Do I need to change EditorView?**
A: No. The toolbar is integrated in MarkdownTextEditor. EditorView's auto-save and highlighting pipelines work unchanged.

**Q: What if user selects 100KB of text and bolds it?**
A: Still fast. The mutation is O(n) but happens once. Regular typing also copies entire text on each keystroke.

**Q: Can I add more formatting buttons later?**
A: Yes. Add more cases to FormattingCommand enum, more methods to FormattingService, more buttons to FormattingToolbar. Phases are extensible.

---

## For Reviewers

When reviewing the implementation:

1. **Check ARCHITECTURE_TOOLBAR.md** for the design intent
2. **Check ROADMAP_IMPLICATIONS.md** for phase-by-phase validation steps
3. **Verify no changes to EditorView, AppState, MarkdownDocument** (should be clean)
4. **Validate undo/redo** with Unit tests in Phase 1
5. **Test integration** in Phase 3 simulator
6. **Run full Phase 4 tests** before merge

---

## Document Versions

| Document | Date | Status | Use For |
|----------|------|--------|---------|
| TOOLBAR_INTEGRATION_SUMMARY.md | 2026-03-26 | ✅ Final | Quick reference |
| ARCHITECTURE_TOOLBAR.md | 2026-03-26 | ✅ Final | Implementation guide |
| ROADMAP_IMPLICATIONS.md | 2026-03-26 | ✅ Final | Phase planning |

---

**Research Status:** ✅ COMPLETE
**Ready for Phase Execution:** ✅ YES
**Next Step:** Begin Phase 1 (FormattingService implementation)

---

*Formatting Toolbar Integration Research*
*iOS Markdown Editor v1.1*
*Researched: 2026-03-26*
