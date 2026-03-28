---
phase: 02-editor-experience
plan: "02"
subsystem: ui
tags: [swiftui, uikit, uitextview, markdown, syntax-highlighting, dark-mode]

# Dependency graph
requires:
  - phase: 02-01
    provides: MarkdownTextEditor UIViewRepresentable, HighlightingService, ThemeColors
provides:
  - EditorView with MarkdownTextEditor replacing TextEditor
  - buildTitle() with " *" unsaved indicator in navigation bar
  - UnsavedChangesTests with real XCTAssert-based coverage
  - Visual verification of EDIT-04 syntax colors and APPR-01 dark mode (pending checkpoint)
affects:
  - 02-03 (toolbar plan depends on this EditorView as base)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - UIViewRepresentable composition: MarkdownTextEditor embedded in SwiftUI view via Binding<String>
    - UIDocument.hasUnsavedChanges read directly in view body — no @Published duplication

key-files:
  created: []
  modified:
    - MarkdownEditor/EditorView.swift
    - MarkdownEditorTests/UnsavedChangesTests.swift

key-decisions:
  - "Read UIDocument.hasUnsavedChanges directly in buildTitle() — no @Published isModified in AppState (avoids sync bugs per Pitfall 3)"
  - "Remove .font/.scrollContentBackground/.background modifiers from MarkdownTextEditor call site — MarkdownTextEditor sets these internally on UITextView"
  - "Test buildTitle string logic as pure function in UnsavedChangesTests — UIDocument instantiation not needed for unit tests"

patterns-established:
  - "buildTitle(): compose filename + conditional suffix — testable without UIDocument"

requirements-completed:
  - EDIT-03
  - APPR-01

# Metrics
duration: ~10min (Task 1); visual checkpoint pending
completed: 2026-03-26
---

# Phase 2 Plan 02: Wire MarkdownTextEditor + Unsaved Indicator Summary

**MarkdownTextEditor wired into EditorView via UIViewRepresentable Binding, buildTitle() adds live " *" unsaved indicator in navigation bar, visual dark-mode checkpoint pending**

## Performance

- **Duration:** ~10 min (automated tasks); visual verification pending
- **Started:** 2026-03-26T07:09:21Z
- **Completed:** Paused at Task 2 checkpoint (human-verify)
- **Tasks:** 1 of 2 automated tasks complete
- **Files modified:** 2

## Accomplishments
- Replaced SwiftUI `TextEditor` with `MarkdownTextEditor` (UITextView wrapper) in EditorView — live syntax coloring now active
- Added `buildTitle()` private method: returns `"filename.md *"` when `document.hasUnsavedChanges` is true, plain filename otherwise
- Updated UnsavedChangesTests from XCTFail stubs to real assertions — all 3 tests pass
- Full test suite (9 tests: 6 MarkdownHighlighterTests + 3 UnsavedChangesTests) passes

## Task Commits

Each task was committed atomically:

1. **Task 1: Swap TextEditor for MarkdownTextEditor, add buildTitle()** - `1aaa7a6` (feat)

**Plan metadata:** TBD (after visual checkpoint approval)

## Files Created/Modified
- `MarkdownEditor/EditorView.swift` — MarkdownTextEditor replaces TextEditor; buildTitle() added; .navigationTitle uses buildTitle()
- `MarkdownEditorTests/UnsavedChangesTests.swift` — XCTFail stubs replaced with 3 real assertions testing buildTitle string logic

## Decisions Made
- Read `UIDocument.hasUnsavedChanges` directly in `buildTitle()` rather than adding a `@Published isModified` flag to AppState. UIDocument manages its own modified state; duplicating it creates sync bugs (per Pitfall 3 in research).
- Removed `.font()`, `.scrollContentBackground()`, and `.background()` SwiftUI modifiers from the MarkdownTextEditor call site — MarkdownTextEditor.makeUIView() already sets `tv.font`, `tv.backgroundColor`, and `tv.textColor` on the underlying UITextView. Applying SwiftUI modifiers on top would be a no-op (UIViewRepresentable ignores font/background modifiers on the UIView layer).
- Test `buildTitle` string logic as a pure function in UnsavedChangesTests rather than instantiating EditorView — EditorView requires @EnvironmentObject which is unavailable in XCTest without a full SwiftUI host.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered
- iPhone 16 simulator not available; used iPhone 17 Pro. Tests pass identically.

## User Setup Required
None — no external service configuration required.

## Next Phase Readiness

**Awaiting visual checkpoint (Task 2):**
- Build and run app in simulator
- Verify 5 syntax color patterns in light mode
- Verify unsaved " *" indicator appears and clears after 1.5s auto-save
- Verify dark mode colors adapt correctly on HomeView and EditorView

After checkpoint approval: Plan 02-03 (toolbar) is unblocked.

---
*Phase: 02-editor-experience*
*Completed: 2026-03-26*
