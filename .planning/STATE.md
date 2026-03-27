---
gsd_state_version: 1.0
milestone: v1.2
milestone_name: Markdown Preview
status: roadmap_created
stopped_at: Roadmap created — ready to plan Phase 5
last_updated: "2026-03-27T00:00:00.000Z"
progress:
  total_phases: 2
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
---

# Project State: iOS Markdown Editor

**Project:** iOS Markdown Editor
**Core Value:** A focused markdown editor that works with any file source — open from anywhere, edit, save back.

**Initialized:** 2026-03-25

---

## Current Position

Milestone: v1.2 Markdown Preview
Phase: None started
Status: Roadmap created — ready to plan Phase 5

Progress: ░░░░░░░░░░ 0/2 phases complete

---

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-27)

**Core value:** Open markdown files from anywhere, edit, save back — including dot folders other apps hide
**Current focus:** v1.2 Markdown Preview — WKWebView renderer with edit/preview toggle
**Shipped:** v1.0 (2026-03-26), v1.1 (2026-03-27)

---

## Roadmap Status

**v1.2 Phases Defined:** 2

- Phase 5: Preview Infrastructure (PREV-02, PREV-03, PREV-04, PREV-05, PREV-06, PREV-07, PREV-09)
- Phase 6: Preview Integration (PREV-01, PREV-08)

**Requirements Coverage:** 9/9 v1.2 requirements mapped ✓

**Next:** Plan Phase 5

---

## Architecture Context (v1.2)

Key decisions already made (from orchestrator/user):
- **Renderer:** WKWebView + JavaScript markdown library (bundled in app bundle, no network)
- **Toggle:** Nav bar button in editor; swaps UITextView for WKWebView (one view at a time, no split)
- **Link handling:** WKNavigationDelegate intercepts link taps; opens SFSafariViewController
- **Dark mode:** CSS `prefers-color-scheme` media query in injected HTML/CSS

Existing architecture to integrate with:
- UITextView wrapped in UIViewRepresentable (EditorView)
- UIDocument for file coordination
- HighlightingService (regex-based, NSAttributedString)
- UIToolbar as inputAccessoryView (keyboard toolbar)

TDD pattern: Wave 0 failing stubs before production code (established in v1.1)

---

## Critical Pitfalls (v1.2 — anticipate)

1. **WKWebView loading timing** — `loadHTMLString` is async; delegate `didFinish` must gate any subsequent JS calls
2. **Dark mode in WKWebView** — Must inject CSS with `prefers-color-scheme`; setting `.overrideUserInterfaceStyle` alone is insufficient for web content
3. **Link interception** — Must implement `decidePolicyFor navigationAction`; default behavior opens Safari app, not SFSafariViewController
4. **JS library bundling** — Library file must be in Copy Bundle Resources, not just added to project; verify with `Bundle.main.url(forResource:)`
5. **Toggle state** — Editor text must not be re-read from UIDocument on each toggle; keep in-memory string consistent with UITextView content

---

## Key Decisions (v1.2)

| Decision | Rationale | Status |
|----------|-----------|--------|
| WKWebView + JS library for rendering | Full markdown fidelity, handles tables/code blocks; no custom parser needed | ✓ Approved |
| One view at a time (no split screen) | iPhone screen too narrow; simpler state management | ✓ Approved |
| SFSafariViewController for links | In-app browsing, no app switch, standard iOS pattern | ✓ Approved |
| CSS prefers-color-scheme for dark mode | Automatic with system; no UIKit override needed | ✓ Planned |

---

## Session Continuity

Last session: 2026-03-27
Stopped at: Roadmap created for v1.2
Resume with: `/gsd:plan-phase 5`

---

*State initialized: 2026-03-25*
*Last updated: 2026-03-27 — v1.2 roadmap complete, ready to plan Phase 5*
