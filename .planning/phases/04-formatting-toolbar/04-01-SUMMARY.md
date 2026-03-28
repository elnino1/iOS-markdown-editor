---
phase: 04-formatting-toolbar
plan: 01
subsystem: testing
tags: [xctest, swift, tdd, wave0, stubs]

# Dependency graph
requires: []
provides:
  - "Failing XCTest stubs for all 8 Phase 4 requirements (FMT-01, FMT-02, FMT-03, FMT-04, UNDO-01, UNDO-02, TOOL-01, TOOL-02)"
  - "MarkdownEditorTests Xcode target with FormattingOperationsTests, UndoRedoTests, FormattingToolbarTests registered"
affects: [04-02, 04-03]

# Tech tracking
tech-stack:
  added: []
  patterns: ["Wave 0 stub pattern: XCTFail('Not yet implemented') in each test method before production code"]

key-files:
  created:
    - MarkdownEditorTests/FormattingOperationsTests.swift
    - MarkdownEditorTests/UndoRedoTests.swift
    - MarkdownEditorTests/FormattingToolbarTests.swift
  modified:
    - MarkdownEditor.xcodeproj/project.pbxproj

key-decisions:
  - "All new test files must be registered in project.pbxproj to be compiled into the MarkdownEditorTests target"

patterns-established:
  - "Wave 0 stubs: each test method calls XCTFail with 'Not yet implemented' message for intentional red state"

requirements-completed: [FMT-01, FMT-02, FMT-03, FMT-04, UNDO-01, UNDO-02, TOOL-01, TOOL-02]

# Metrics
duration: 37min
completed: 2026-03-26
---

# Phase 4 Plan 01: Wave 0 Failing Test Stubs Summary

**16 XCTest stubs across 3 files covering all 8 Phase 4 requirements, compiled and failing intentionally as Wave 0 TDD scaffolding**

## Performance

- **Duration:** ~37 min
- **Started:** 2026-03-26T18:34:48Z
- **Completed:** 2026-03-26T19:11:50Z
- **Tasks:** 2 of 2
- **Files modified:** 4

## Accomplishments

- Created FormattingOperationsTests.swift with 9 XCTFail stubs covering FMT-01 through FMT-04
- Created UndoRedoTests.swift with 5 XCTFail stubs covering UNDO-01 and UNDO-02
- Created FormattingToolbarTests.swift with 2 XCTFail stubs covering TOOL-01 and TOOL-02
- Registered all 3 new test files in MarkdownEditor.xcodeproj so they compile and run
- All 16 new stubs fail intentionally; all 8 prior tests remain green

## Task Commits

Each task was committed atomically:

1. **Task 1: Create FormattingOperationsTests.swift with failing stubs** - `4ccfc88` (test)
2. **Task 2: Create UndoRedoTests.swift and FormattingToolbarTests.swift with failing stubs** - `674b2b8` (test)

## Files Created/Modified

- `MarkdownEditorTests/FormattingOperationsTests.swift` - 9 XCTFail stubs for FMT-01, FMT-02, FMT-03, FMT-04
- `MarkdownEditorTests/UndoRedoTests.swift` - 5 XCTFail stubs for UNDO-01, UNDO-02
- `MarkdownEditorTests/FormattingToolbarTests.swift` - 2 XCTFail stubs for TOOL-01, TOOL-02
- `MarkdownEditor.xcodeproj/project.pbxproj` - Registered all 3 new test files in MarkdownEditorTests target

## Decisions Made

None - followed plan as specified.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Registered new test files in Xcode project**
- **Found during:** Task 1 verification (new test classes absent from test run)
- **Issue:** Swift test files created on disk are not automatically added to the Xcode target; xcodebuild ran but only discovered MarkdownHighlighterTests and UnsavedChangesTests
- **Fix:** Added 3 PBXBuildFile entries, 3 PBXFileReference entries, updated PBXGroup, and updated PBXSourcesBuildPhase in project.pbxproj
- **Files modified:** MarkdownEditor.xcodeproj/project.pbxproj
- **Verification:** Full test run shows all 16 new stubs appearing and failing; 8 existing tests remain green
- **Committed in:** 674b2b8 (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Required for correctness — without pbxproj registration the stubs would not run at all. No scope creep.

## Issues Encountered

xcodebuild uses scheme "MarkdownEditor" (not "iOS-markdown-editor" as referenced in plan verify commands), and requires simulator "iPhone 17" (not "iPhone 16" — unavailable in this environment). Plan verify commands needed adjustment; tests passed correctly once correct scheme/destination were used.

## Self-Check

- [x] MarkdownEditorTests/FormattingOperationsTests.swift exists with 9 XCTFail stubs
- [x] MarkdownEditorTests/UndoRedoTests.swift exists with 5 XCTFail stubs
- [x] MarkdownEditorTests/FormattingToolbarTests.swift exists with 2 XCTFail stubs
- [x] xcodebuild TEST FAILED (16 intentional failures, BUILD SUCCEEDED, no compile errors)
- [x] Existing MarkdownHighlighterTests (5) and UnsavedChangesTests (3) remain green

## Next Phase Readiness

- Wave 0 complete: all test method names exist for Nyquist compliance
- Plans 04-02 and 04-03 can now reference test methods without MISSING verify errors
- Production code for formatting operations (04-02) and undo/redo (04-03) can now be implemented against these stubs

---
*Phase: 04-formatting-toolbar*
*Completed: 2026-03-26*
