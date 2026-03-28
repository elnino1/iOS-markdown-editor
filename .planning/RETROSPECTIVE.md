# Project Retrospective: iOS Markdown Editor

---

## Milestone: v1.1 — Formatting Toolbar

**Shipped:** 2026-03-27
**Phases:** 1 (Phase 4) | **Plans:** 3 | **Git commits:** ~20

### What Was Built

- Wave 0 TDD scaffolding: 16 failing stubs across FormattingOperationsTests, UndoRedoTests, FormattingToolbarTests
- `FormattingService` pure enum: bold, italic, bullet, table via UITextInput protocol with atomic undo grouping
- 7-button UIToolbar docked above keyboard via `inputAccessoryView`, undo/redo state reflects canUndo/canRedo
- Toggle-off behavior added post-phase: bold/italic/bullet detect existing formatting and strip markers

### What Worked

- **Wave 0 TDD** enforced a clear contract before production code — no surprises at integration time
- **UITextInput protocol** (replace/insertText) instead of textStorage was the right call from the start; undo just worked
- **Atomic undo grouping** (beginUndoGrouping/endUndoGrouping) made multi-step ops single-step to the user
- **inputAccessoryView pattern** — toolbar disappeared with keyboard automatically, no custom show/hide logic

### What Was Inefficient

- Syntax highlighting initially mutated textStorage directly, corrupting the undo stack — required a fix pass (3 commits). Should have audited all textStorage write sites before starting Phase 4.
- Toggle-off behavior was not in the original plan and had to be added as a follow-up. Worth including in initial requirements: "buttons should toggle, not stack".

### Patterns Established

- All text mutations must go through UITextInput (`replace(_:withText:)` / `insertText(_:)`) — never `textStorage` directly
- Formatting detection handles two cases: selection includes markers, and markers surround selection
- Italic strip guard must exclude `**` bold pairs (single `*` check + neighbor check)

### Key Lessons

1. **Audit undo-sensitive code before adding toolbar** — syntax highlighting was mutating textStorage which broke undo; fixed but cost 3 commits
2. **Toggle behavior is UX-obvious and should be in requirements** — users expect tap-to-toggle, not tap-to-stack
3. **UITextInput is the right abstraction level** for text manipulation in UITextView-backed editors

### Cost Observations

- Sessions: 2
- Notable: Wave 0 stubs caught a Xcode project registration issue early (files not in pbxproj); fixed before production code touched the codebase

---

## Milestone: v1.0 — MVP

**Shipped:** 2026-03-26
**Phases:** 3 (Phases 1-3) | **Plans:** 9 | **Git commits:** ~60

### What Was Built

- Full open/edit/save loop: UIDocumentPickerViewController + UIDocument + "Open With" URL handling
- HighlightingService with 5 regex patterns, ThemeColors for semantic light/dark, UITextView via UIViewRepresentable
- Error handling, large file warnings (>500KB), encoding fallback, recently opened files list (UserDefaults)

### What Worked

- UIDocument gave file coordination and undo for free — right foundation choice
- Delegating file browsing to the source app (Google Drive etc.) solved the dot-folder problem without any custom browser code
- Regex-based highlighting was simple and fast enough; no need for a full parser

### Key Lessons

1. **iOS 26 simulator has a file picker callback bug** — file picker showed but callbacks never fired; tested on real device instead
2. **UIDocument auto-coordinates reads/writes** — don't bypass it with direct FileManager calls

---

## Cross-Milestone Trends

| Metric | v1.0 | v1.1 |
|--------|------|------|
| Phases | 3 | 1 |
| Plans | 9 | 3 |
| Days | 1 | 2 |
| Tests added | 8 | 22 |
| Undo-related issues | 0 | 1 (fixed) |
