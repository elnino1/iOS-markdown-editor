# Roadmap: iOS Markdown Editor

**Project:** iOS Markdown Editor
**Core Value:** A focused markdown editor that works with any file source — open from anywhere, edit, save back.

**Created:** 2026-03-25
**Updated:** 2026-03-25 (architectural pivot — removed Drive API/OAuth phases, adopted document sharing)
**Status:** Planning

---

## Phases

- [ ] **Phase 1: Core** - Open files + raw text editing + save back
- [ ] **Phase 2: Editor Experience** - Syntax coloring, unsaved indicator, light/dark mode
- [ ] **Phase 3: Polish** - Edge cases, error handling, refinements

---

## Phase Details

### Phase 1: Core

**Goal:** Deliver the minimal working loop — open a markdown file (from picker or "Open With"), edit it, save it back

**Depends on:** Nothing (first phase)

**Requirements Mapped:** FILE-01, FILE-02, EDIT-01, EDIT-02

**Success Criteria** (what must be TRUE when this phase completes):
1. User can tap "Open File" and browse their files via iOS file picker (including iCloud, local storage)
2. User can open a markdown file sent from Google Drive (or any app) via the iOS "Open With" / share sheet
3. User can edit the opened file content as raw text with cursor control and system undo/redo
4. User can save edits back to the original file location (changes persist when reopening in source app)

**Plan:** TBD

---

### Phase 2: Editor Experience

**Goal:** Make the editor pleasant to use — syntax coloring, change tracking, and appearance support

**Depends on:** Phase 1 (requires working editor)

**Requirements Mapped:** EDIT-03, EDIT-04, APPR-01

**Success Criteria** (what must be TRUE when this phase completes):
1. Editor applies markdown syntax coloring (headings, bold, italic, code, links visually distinct)
2. App shows a clear visual indicator when file has unsaved changes (e.g. dot in title bar, modified badge)
3. App looks correct in both light and dark mode throughout all screens

**Plan:** TBD

---

### Phase 3: Polish

**Goal:** Handle edge cases, improve reliability, and smooth rough edges

**Depends on:** Phase 2 (requires complete core workflow)

**Requirements Mapped:** (none mandatory; phase for hardening)

**Success Criteria** (what must be TRUE when this phase completes):
1. App shows meaningful error messages when file operations fail (permission denied, file not found, etc.)
2. App handles large files gracefully (warns or degrades gracefully above a reasonable threshold)
3. App handles non-UTF-8 encoded files without corrupting content
4. Recently opened files list lets user quickly reopen previous files without re-navigating

**Plan:** TBD

---

## Progress Tracking

| Phase | Goal | Requirements | Status | Completed |
|-------|------|--------------|--------|-----------|
| 1 - Core | Open + edit + save | 4 (FILE-01, FILE-02, EDIT-01, EDIT-02) | Not started | - |
| 2 - Editor Experience | Coloring + indicator + appearance | 3 (EDIT-03, EDIT-04, APPR-01) | Not started | - |
| 3 - Polish | Edge cases | 0 (optional) | Not started | - |

---

## Coverage Summary

**v1 Requirements:** 7 total
**Mapped to phases:** 7
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
```

---

*Roadmap created: 2026-03-25*
*Updated: 2026-03-25 — architectural pivot to UIDocument / document sharing model*
*Ready for planning: `/gsd:plan-phase 1`*
