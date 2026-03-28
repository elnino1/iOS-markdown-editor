# Roadmap: iOS Markdown Editor

**Project:** iOS Markdown Editor
**Core Value:** A focused markdown editor that works with any file source — open from anywhere, edit, save back.

**Created:** 2026-03-25
**Updated:** 2026-03-27 (v1.2 roadmap created)
**Status:** Active — v1.2 Markdown Preview

---

## Milestones

- ✅ **v1.0 MVP** — Phases 1-3 (shipped 2026-03-26)
- ✅ **v1.1 Formatting Toolbar** — Phase 4 (shipped 2026-03-27)
- 🔄 **v1.2 Markdown Preview** — Phases 5-6 (in progress)

---

## Phases

<details>
<summary>✅ v1.0 MVP (Phases 1-3) — SHIPPED 2026-03-26</summary>

- [x] **Phase 1: Core** — Open files + raw text editing + save back (completed 2026-03-25)
- [x] **Phase 2: Editor Experience** — Syntax coloring, unsaved indicator, light/dark mode (completed 2026-03-26)
- [x] **Phase 3: Polish** — Edge cases, error handling, recently opened files (completed 2026-03-26)

Full details: `.planning/milestones/v1.0-ROADMAP.md`

</details>

<details>
<summary>✅ v1.1 Formatting Toolbar (Phase 4) — SHIPPED 2026-03-27</summary>

- [x] **Phase 4: Formatting Toolbar** — Toolbar infrastructure + formatting actions + undo/redo (completed 2026-03-27)

Full details: `.planning/milestones/v1.1-ROADMAP.md`

</details>

### v1.2 Markdown Preview

- [x] **Phase 5: Preview Infrastructure** — WKWebView wrapper, JS markdown library bundled, full rendering pipeline with dark mode support (completed 2026-03-28)
- [ ] **Phase 6: Preview Integration** — Toggle button wired into editor nav bar, links open in SFSafariViewController

---

## Phase Details

### Phase 5: Preview Infrastructure
**Goal**: A self-contained markdown renderer exists that correctly renders all required markdown elements and respects system appearance
**Depends on**: Phase 4 (existing editor)
**Requirements**: PREV-02, PREV-03, PREV-04, PREV-05, PREV-06, PREV-07, PREV-09
**Plans:** 3/3 plans complete

Plans:
- [ ] 05-01-PLAN.md — Wave 0: failing test stubs (MarkdownRendererTests) + static assets (markdown-preview.css, markdown-preview.js)
- [ ] 05-02-PLAN.md — MarkdownRenderer.swift: synchronous HTML generation via JavaScriptCore + markdown-it (tests go GREEN)
- [ ] 05-03-PLAN.md — PreviewView.swift: WKWebView UIViewRepresentable wrapper + human dark mode verification

**Success Criteria** (what must be TRUE):
  1. Given a string with H1/H2/H3 headings, the renderer displays them with distinct visual sizes and weights
  2. Given a string with `**bold**` and `*italic*`, the renderer displays styled text (not raw markers)
  3. Given a string with bullet lists, numbered lists, and fenced code blocks, the renderer displays proper indentation, numbering, and monospace fonts
  4. Given a string with a markdown table, the renderer displays a visual grid with borders and aligned columns
  5. The rendered HTML matches the system light/dark mode setting without any manual user action

### Phase 6: Preview Integration
**Goal**: Users can switch between editing raw markdown and reading the rendered preview without leaving the editor
**Depends on**: Phase 5
**Requirements**: PREV-01, PREV-08
**Success Criteria** (what must be TRUE):
  1. A button in the editor navigation bar switches the view from the UITextView editor to the rendered preview and back; the button label or icon reflects the current mode
  2. Tapping a link in the preview opens SFSafariViewController inline (no app switch, no Safari app)
  3. Returning from preview to edit mode leaves the cursor position and text unchanged

---

## Progress Tracking

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Core | v1.0 | 3/3 | Complete | 2026-03-25 |
| 2. Editor Experience | v1.0 | 3/3 | Complete | 2026-03-26 |
| 3. Polish | v1.0 | 3/3 | Complete | 2026-03-26 |
| 4. Formatting Toolbar | v1.1 | 3/3 | Complete | 2026-03-27 |
| 5. Preview Infrastructure | 3/3 | Complete    | 2026-03-28 | - |
| 6. Preview Integration | v1.2 | 0/? | Not started | - |

---

*Updated: 2026-03-27 — Phase 5 planned (3 plans). Next: `/gsd:execute-phase 5`*
