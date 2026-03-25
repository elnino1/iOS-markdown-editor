---
phase: 01-foundation
plan: 03
subsystem: ui
tags: [swiftui, uikit, uidocument, texteditor, autosave, combine]

# Dependency graph
requires:
  - phase: 01-01
    provides: MarkdownDocument UIDocument subclass with text property, updateChangeCount, hasUnsavedChanges
  - phase: 01-02
    provides: AppState with open(url:) and closeCurrentDocument(completion:); EditorView stub file

provides:
  - Full-screen raw text editor (EditorView) with monospaced TextEditor, 1.5s auto-save, nav bar, and Close button
  - Unsaved-changes alert (Save / Discard / Cancel) triggered when opening a second file while editing
  - AppState.pendingOpenURL published property for deferred open-after-save coordination
  - AppState.openAfterResolvingConflict(url:) method for post-alert direct open

affects: [02-browse, 03-edit, 04-sync]

# Tech tracking
tech-stack:
  added: [Combine (AnyCancellable saveTimer debounce)]
  patterns:
    - Auto-save via updateChangeCount(.done) + UIDocument built-in save mechanism
    - Debounce with Combine Just + .delay scheduler on RunLoop.main
    - pendingOpenURL @Published property pattern for cross-view coordination without direct view-to-view coupling

key-files:
  created: []
  modified:
    - MarkdownEditor/EditorView.swift
    - MarkdownEditor/AppState.swift

key-decisions:
  - "iOS 16 compatible onChange: used single-argument form .onChange(of:) { value in } instead of two-argument iOS 17+ form"
  - "Auto-save delay: 1.5 seconds (within 1-2s discretion range from CONTEXT.md)"
  - "No explicit Save button: auto-save only, per CONTEXT.md locked decision"
  - "TextEditor over UITextView wrapper for Phase 1: files expected small, simpler implementation"
  - "pendingOpenURL in AppState rather than direct EditorView state: enables open(url:) calls from any source (onOpenURL, file picker) to trigger the alert"

patterns-established:
  - "Auto-save pattern: doc.text mutation in Binding.set -> scheduleSave -> debounce -> updateChangeCount(.done)"
  - "UIDocument conflict guard: AppState.open(url:) checks hasUnsavedChanges -> sets pendingOpenURL -> EditorView .onChange observes -> shows alert"

requirements-completed: [EDIT-01, EDIT-02]

# Metrics
duration: 3min
completed: 2026-03-25
---

# Phase 1 Plan 03: EditorView Summary

**Full-screen raw TextEditor with 1.5s Combine-debounced auto-save and UIDocument unsaved-changes guard alert (Save/Discard/Cancel)**

## Performance

- **Duration:** 3 min
- **Started:** 2026-03-25T21:12:05Z
- **Completed:** 2026-03-25T21:15:06Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Full-screen SwiftUI TextEditor with monospaced font, proper dark mode support, and keyboard avoidance
- Auto-save: 1.5s debounce via Combine's `Just + .delay`, calls `updateChangeCount(.done)` to trigger UIDocument's built-in save
- Unsaved-changes alert with Save / Discard / Cancel options, coordinated via `AppState.pendingOpenURL` publisher
- Nav bar shows filename from `fileURL.lastPathComponent`; Close button calls `closeCurrentDocument()`
- AppState extended with `pendingOpenURL` and `openAfterResolvingConflict(url:)` to complete the open-while-editing guard loop

## Task Commits

1. **Task 1: Build EditorView with raw text editing and auto-save** - `504d144` (feat)
2. **Task 2: Add pendingOpenURL guard to AppState** - `0486659` (feat)

## Files Created/Modified

- `MarkdownEditor/EditorView.swift` - Full-screen editor replacing Plan 02 stub; TextEditor, auto-save timer, unsaved-changes alert, pendingOpenURL observer
- `MarkdownEditor/AppState.swift` - Added `pendingOpenURL`, `openAfterResolvingConflict(url:)`, `_openDirectly(url:)` private helper

## Decisions Made

- iOS 16 compatibility: plan specified two-argument `.onChange(of:) { _, url in }` which is iOS 17+ only. Used single-argument `.onChange(of:) { url in }` form instead (Rule 1 auto-fix).
- `pendingOpenURL` lives in AppState (not local EditorView state) so that `open(url:)` calls arriving from `onOpenURL` or any other source can trigger the unsaved-changes flow without EditorView needing to intercept every open call.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] iOS 16 incompatible onChange form**
- **Found during:** Task 1 (build verification)
- **Issue:** Plan's code sample used `onChange(of:) { _, url in }` two-argument closure, which requires iOS 17.0+. Deployment target is iOS 16.0, causing build error.
- **Fix:** Changed to single-argument `.onChange(of: appState.pendingOpenURL) { url in }` form, which is available from iOS 14+.
- **Files modified:** MarkdownEditor/EditorView.swift
- **Verification:** `xcodebuild` returned BUILD SUCCEEDED after fix
- **Committed in:** `504d144` (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - bug in plan's code sample)
**Impact on plan:** Required for iOS 16 compatibility. No scope creep. Behavior identical.

## Issues Encountered

None — after fixing the onChange compatibility issue, build succeeded immediately.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Complete open-edit-save loop is now functional: open file -> edit -> auto-save -> close
- Foundation phase (01) is complete: MarkdownDocument, AppState, HomeView, EditorView all implemented
- Phase 2 (Browse) can build on this shell; document model and app state patterns are established

---
*Phase: 01-foundation*
*Completed: 2026-03-25*
