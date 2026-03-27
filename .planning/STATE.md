---
gsd_state_version: 1.0
milestone: v1.2
milestone_name: Markdown Preview
status: defining_requirements
stopped_at: Requirements defined — creating roadmap
last_updated: "2026-03-27T00:00:00.000Z"
progress:
  total_phases: 1
  completed_phases: 1
  total_plans: 3
  completed_plans: 3
---

# Project State: iOS Markdown Editor

**Project:** iOS Markdown Editor
**Core Value:** A focused markdown editor that works with any file source — open from anywhere, edit, save back.

**Initialized:** 2026-03-25

---

## Current Position

Phase: Not started (defining requirements for v1.2)
Status: Roadmap being created

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-27)

**Core value:** Open markdown files from anywhere, edit, save back — including dot folders other apps hide
**Current focus:** v1.2 Markdown Preview — WKWebView renderer with edit/preview toggle
**Shipped:** v1.0 (2026-03-26), v1.1 (2026-03-27)

---

## Roadmap Status

**v1.1 Phases Defined:** 1

- Phase 4: Formatting Toolbar (TOOL-01, TOOL-02, FMT-01, FMT-02, FMT-03, FMT-04, UNDO-01, UNDO-02)

**Requirements Coverage:** 8/8 v1.1 requirements mapped ✓

**Next:** Plan Phase 4

---

## Critical Pitfalls (Phase 4)

From research/SUMMARY.md:

1. **Direct textStorage modification** — Use UITextInput.insertText/replace only; never textStorage directly
2. **Cursor position loss** — Save selectedRange before insertion; recalculate offsets; restore after
3. **NSRange vs Swift String** — All position math uses NSString (UTF-16); never Swift String.count
4. **Undo registration order** — Register undo BEFORE modifying text; use beginUndoGrouping for multi-step ops
5. **Line range for bullet/table** — Use NSString.lineRange(for:); never String.split(separator:)

---

## Key Decisions (v1.1)

| Decision | Rationale | Status |
|----------|-----------|--------|
| SwiftUI .toolbar(placement: .keyboard) | Simpler than inputAccessoryView; iOS 16+ supported | ✓ Planned |
| UITextInput protocol for all text changes | Integrates with UndoManager; avoids undo stack corruption | ✓ Planned |
| Atomic undo grouping for bold/italic wrapping | Two insertions must undo as one step | ✓ Planned |
| New Swift test files must be registered in project.pbxproj | Files on disk are not auto-discovered by Xcode; PBXBuildFile + PBXFileReference entries required | ✓ 04-01 |
| FormattingService as enum with static methods | No instance needed; clean separation from Coordinator; fully unit-testable | ✓ 04-02 |
| text = tv.text sync in Coordinator apply* methods | Syncs SwiftUI binding without triggering textViewDidChange delegate (programmatic changes don't fire delegate) | ✓ 04-02 |

---

## Session Continuity

Last session: 2026-03-26T19:39:00.000Z
Stopped at: Completed 04-02-PLAN.md (FormattingService + Coordinator methods)
Resume file: None

---

*State initialized: 2026-03-25*
*Last updated: 2026-03-26 — v1.1 roadmap complete*
