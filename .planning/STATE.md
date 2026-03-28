---
gsd_state_version: 1.0
milestone: v1.2
milestone_name: Markdown Preview
status: unknown
stopped_at: Completed 06-02-PLAN.md
last_updated: "2026-03-28T20:41:46.499Z"
progress:
  total_phases: 2
  completed_phases: 2
  total_plans: 5
  completed_plans: 5
---

# Project State: iOS Markdown Editor

**Project:** iOS Markdown Editor
**Core Value:** A focused markdown editor that works with any file source — open from anywhere, edit, save back.

**Initialized:** 2026-03-25

---

## Current Position

Phase: 6 (Preview Integration) — COMPLETE
Plan: 2 of 2 (all plans done)

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-27)

**Core value:** Open markdown files from anywhere, edit, save back — including dot folders other apps hide
**Current focus:** Phase 6 — Preview Integration
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
4. **JS library bundling** — Library file must be in Copy Bundle Resources; use `Bundle(for: SomeClass.self)` not `Bundle.main` in testable code — `Bundle.main` fails in unit test bundles
5. **Toggle state** — Editor text must not be re-read from UIDocument on each toggle; keep in-memory string consistent with UITextView content

---

## Key Decisions (v1.2)

| Decision | Rationale | Status |
|----------|-----------|--------|
| WKWebView + JS library for rendering | Full markdown fidelity, handles tables/code blocks; no custom parser needed | ✓ Approved |
| One view at a time (no split screen) | iPhone screen too narrow; simpler state management | ✓ Approved |
| SFSafariViewController for links | In-app browsing, no app switch, standard iOS pattern | ✓ Approved |
| CSS prefers-color-scheme for dark mode | Automatic with system; no UIKit override needed | ✓ Planned |
| MarkdownRenderer.generateHTML(from:) is static | Tests call it as static method — Plan 02 must match this exact signature | ✓ 05-01 |
| Resources in Copy Bundle Resources build phase | Required for Bundle.main.url(forResource:) to find CSS/JS at runtime | ✓ 05-01 |
| Bundle(for: MarkdownRenderer.self) not Bundle.main | Bundle.main returns test runner bundle during unit tests — class bundle resolves correctly in both contexts | ✓ 05-02 |
| jsonEncoded() wraps in array before JSONSerialization | String is not valid JSON top-level type; serialize [string], strip outer brackets | ✓ 05-02 |
| JSContext UMD shims required for markdown-it | var window=this; var module={exports:{}}; — markdown-it UMD needs these to execute outside browser | ✓ 05-02 |
| PreviewView.swift added to Xcode project build target | File existed on disk from Phase 5 but was never registered in project.pbxproj — required for EditorView to reference it | ✓ 06-01 |
| WKNavigationDelegate link interception: cancel linkActivated + present SFSafariViewController pageSheet | UIApplication.connectedScenes pattern for topmost VC discovery from UIViewRepresentable Coordinator | ✓ 06-02 |

---

## Session Continuity

Last session: 2026-03-28T20:26:18.639Z
Stopped at: Completed 06-02-PLAN.md
Resume with: `/gsd:execute-phase 5`

---

*State initialized: 2026-03-25*
*Last updated: 2026-03-28 — 06-02 complete: PreviewView.Coordinator WKNavigationDelegate upgraded to intercept link taps (linkActivated + http/https) and present SFSafariViewController as a pageSheet; non-link navigations pass through; PREV-08 complete; v1.2 milestone fully delivered*
