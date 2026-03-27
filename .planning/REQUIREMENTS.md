# Requirements: iOS Markdown Editor

**Defined:** 2026-03-27
**Milestone:** v1.2 Markdown Preview
**Core Value:** A focused markdown editor that works with any file source — open from anywhere, edit, save back.

## v1.2 Requirements

### Preview Mode

- [ ] **PREV-01**: User can toggle between edit mode and preview mode via a button in the editor navigation bar
- [ ] **PREV-02**: Preview renders headings (H1–H3) with visual hierarchy (size, weight)
- [ ] **PREV-03**: Preview renders `**bold**` and `*italic*` as styled text
- [ ] **PREV-04**: Preview renders bullet lists (`- `) and numbered lists (`1. `) with proper indentation
- [ ] **PREV-05**: Preview renders fenced code blocks with monospace font
- [ ] **PREV-06**: Preview renders inline `code` with monospace font
- [ ] **PREV-07**: Preview renders markdown tables as visual grids
- [ ] **PREV-08**: User can tap a link in preview to open it in an in-app browser (SFSafariViewController)
- [ ] **PREV-09**: Preview matches the system light/dark mode setting

## Future Requirements

### Preview Enhancements

- **PREV-10**: Preview renders images (![alt](url))
- **PREV-11**: Scroll position preserved when toggling between edit and preview
- **PREV-12**: Syntax highlighting in code blocks (language-aware colors)

## Out of Scope

| Feature | Reason |
|---------|--------|
| WYSIWYG editing | Tapping preview to edit inline — too complex for v1.2, deferred |
| Image rendering | Network images add complexity; deferred to future |
| Print / export to PDF | Out of scope for v1.x |
| Split-screen (edit + preview side by side) | iOS phone screen too narrow; iPad future consideration |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| PREV-01 | — | Pending |
| PREV-02 | — | Pending |
| PREV-03 | — | Pending |
| PREV-04 | — | Pending |
| PREV-05 | — | Pending |
| PREV-06 | — | Pending |
| PREV-07 | — | Pending |
| PREV-08 | — | Pending |
| PREV-09 | — | Pending |

**Coverage:**
- v1.2 requirements: 9 total
- Mapped to phases: 0 (pending roadmap)
- Unmapped: 9 ⚠️

---
*Requirements defined: 2026-03-27*
