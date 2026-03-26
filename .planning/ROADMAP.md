# Roadmap: iOS Markdown Editor

**Project:** iOS Markdown Editor
**Core Value:** A focused markdown editor that works with any file source — open from anywhere, edit, save back.

**Created:** 2026-03-25
**Updated:** 2026-03-26 (v1.1 milestone — formatting toolbar)
**Status:** Active

---

## Milestones

- ✅ **v1.0 MVP** - Phases 1-3 (shipped 2026-03-26)
- 🚧 **v1.1 Formatting Toolbar** - Phase 4 (in progress)

---

## Phases

<details>
<summary>✅ v1.0 MVP (Phases 1-3) - SHIPPED 2026-03-26</summary>

- [x] **Phase 1: Core** - Open files + raw text editing + save back (completed 2026-03-25)
- [x] **Phase 2: Editor Experience** - Syntax coloring, unsaved indicator, light/dark mode (completed 2026-03-26)
- [x] **Phase 3: Polish** - Edge cases, error handling, refinements (completed 2026-03-26)

### Phase 1: Core

**Goal:** Deliver the minimal working loop — open a markdown file (from picker or "Open With"), edit it, save it back

**Depends on:** Nothing (first phase)

**Requirements:** FILE-01, FILE-02, EDIT-01, EDIT-02

**Success Criteria** (what must be TRUE when this phase completes):
1. User can tap "Open File" and browse their files via iOS file picker (including iCloud, local storage)
2. User can open a markdown file sent from Google Drive (or any app) via the iOS "Open With" / share sheet
3. User can edit the opened file content as raw text with cursor control and system undo/redo
4. User can save edits back to the original file location (changes persist when reopening in source app)

**Plans:** 3/3 plans complete

Plans:
- [x] 01-01-PLAN.md — Xcode project scaffold + MarkdownDocument (UIDocument subclass) + AppState
- [x] 01-02-PLAN.md — HomeView empty state + file picker (FILE-01) + "Open With" URL handler (FILE-02)
- [x] 01-03-PLAN.md — EditorView raw text editing + auto-save + unsaved-changes alert (EDIT-01, EDIT-02)

---

### Phase 2: Editor Experience

**Goal:** Make the editor pleasant to use — syntax coloring, change tracking, and appearance support

**Depends on:** Phase 1 (requires working editor)

**Requirements:** EDIT-03, EDIT-04, APPR-01

**Success Criteria** (what must be TRUE when this phase completes):
1. Editor applies markdown syntax coloring (headings, bold, italic, code, links visually distinct)
2. App shows a clear visual indicator when file has unsaved changes (e.g. dot in title bar, modified badge)
3. App looks correct in both light and dark mode throughout all screens

**Plans:** 3/3 plans complete

Plans:
- [x] 02-00-PLAN.md — XCTest target scaffold + failing test stubs for EDIT-03, EDIT-04
- [x] 02-01-PLAN.md — HighlightingService (regex + AttributedString) + ThemeColors (semantic light/dark) + MarkdownTextEditor (UIViewRepresentable)
- [x] 02-02-PLAN.md — Wire MarkdownTextEditor into EditorView + unsaved indicator in title + visual dark mode checkpoint (EDIT-03, APPR-01)

---

### Phase 3: Polish

**Goal:** Handle edge cases, improve reliability, and smooth rough edges

**Depends on:** Phase 2 (requires complete core workflow)

**Requirements:** (none mandatory; phase for hardening)

**Success Criteria** (what must be TRUE when this phase completes):
1. App shows meaningful error messages when file operations fail (permission denied, file not found, etc.)
2. App handles large files gracefully (warns or degrades gracefully above a reasonable threshold)
3. App handles non-UTF-8 encoded files without corrupting content
4. Recently opened files list lets user quickly reopen previous files without re-navigating

**Plans:** 3/3 plans complete

Plans:
- [x] 03-01-PLAN.md — Error alerts for open failures, picker errors, and save failures (FileOperationError enum + alerts in HomeView + EditorView)
- [x] 03-02-PLAN.md — Large file warning + disable highlighting above 500 KB; encoding fallback notification (MarkdownDocument flag + EditorView alerts)
- [x] 03-03-PLAN.md — Recently opened files list (RecentFilesStore + HomeView List section with swipe-to-delete)

</details>

---

### 🚧 v1.1 Formatting Toolbar (In Progress)

**Milestone Goal:** Add a keyboard-docked formatting toolbar so users can apply markdown syntax without typing manually.

- [ ] **Phase 4: Formatting Toolbar** - Toolbar infrastructure + formatting actions + undo/redo

---

## Phase Details

### Phase 4: Formatting Toolbar

**Goal:** Users can apply markdown formatting via toolbar buttons above the keyboard — bold, italic, bullet, table insertion, and undo/redo — without typing syntax manually

**Depends on:** Phase 3 (requires complete editor with UITextView and syntax highlighting)

**Requirements:** TOOL-01, TOOL-02, FMT-01, FMT-02, FMT-03, FMT-04, UNDO-01, UNDO-02

**Success Criteria** (what must be TRUE when this phase completes):
1. A formatting toolbar appears above the keyboard when the editor is active, and disappears when the keyboard is dismissed
2. User can tap the keyboard-dismiss button in the toolbar to close the keyboard without leaving the editor
3. User can tap Bold to wrap selected text in `**markers**`, or insert `**text**` at cursor when nothing is selected
4. User can tap Italic to wrap selected text in `*markers*`, or insert `*text*` at cursor when nothing is selected
5. User can tap Bullet to prefix the current line with `- `, and tap Table to insert a 3-column x 2-row markdown table template at the cursor
6. User can tap Undo and Redo in the toolbar to step through edit history including toolbar-applied formatting

**Plans:** 1/3 plans executed

Plans:
- [ ] 04-01-PLAN.md — XCTest stubs (Wave 0): failing test scaffolding for all 8 requirements
- [ ] 04-02-PLAN.md — FormattingService + Coordinator methods: bold, italic, bullet, table, undo/redo logic
- [ ] 04-03-PLAN.md — Toolbar UI: wire .toolbar(placement: .keyboard) into EditorView + human verification

---

## Progress Tracking

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Core | v1.0 | 3/3 | Complete | 2026-03-25 |
| 2. Editor Experience | v1.0 | 3/3 | Complete | 2026-03-26 |
| 3. Polish | v1.0 | 3/3 | Complete | 2026-03-26 |
| 4. Formatting Toolbar | 1/3 | In Progress|  | - |

---

## Coverage Summary

**v1.0 Requirements:** 7 total — mapped to Phases 1-3 ✓
**v1.1 Requirements:** 8 total — mapped to Phase 4 ✓
**Unmapped (orphaned):** 0

✓ **100% requirement coverage validated**

---

## Dependency Graph

```
Phase 1: Core (open + edit + save)
    ↓
Phase 2: Editor Experience (coloring + appearance)
    ↓
Phase 3: Polish (hardening)
    ↓
Phase 4: Formatting Toolbar (v1.1)
  Wave 1: 04-01 (test stubs)
    ↓
  Wave 2: 04-02 (FormattingService + Coordinator)
    ↓
  Wave 3: 04-03 (toolbar UI + human verification)
```

---

*Roadmap created: 2026-03-25*
*Updated: 2026-03-26 — v1.1 milestone: Phase 4 Formatting Toolbar added (8 requirements)*
*Updated: 2026-03-26 — Phase 4 planned: 3 plans across 3 waves*
