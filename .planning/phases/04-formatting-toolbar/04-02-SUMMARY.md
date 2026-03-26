---
phase: 04-formatting-toolbar
plan: 02
subsystem: formatting-logic
tags: [FormattingService, UITextInput, UndoManager, NSRange, TDD]
dependency_graph:
  requires: [04-01]
  provides: [FormattingService, Coordinator.applyBold, Coordinator.applyItalic, Coordinator.applyBullet, Coordinator.insertTable]
  affects: [MarkdownTextEditor.Coordinator, EditorView (Plan 04-03)]
tech_stack:
  added: [FormattingService]
  patterns: [UITextInput protocol for all text changes, atomic undo grouping via beginUndoGrouping/endUndoGrouping, NSString UTF-16 position math]
key_files:
  created: [MarkdownEditor/FormattingService.swift]
  modified: [MarkdownEditor/MarkdownTextEditor.swift, MarkdownEditorTests/FormattingOperationsTests.swift, MarkdownEditorTests/UndoRedoTests.swift, MarkdownEditor.xcodeproj/project.pbxproj]
decisions:
  - FormattingService implemented as enum (no instances) with static methods — clean separation from UIViewRepresentable Coordinator
  - UITextInput replace(_:withText:) used for selection-replacement, insertText(_:) for cursor-only insertion — preserves undo stack integrity
  - Undo grouping wraps entire operation (beginUndoGrouping before first modification, endUndoGrouping after last) — ensures single undo step per toolbar tap
  - text = tv.text sync in each Coordinator apply* method — notifies SwiftUI binding without triggering textViewDidChange highlight debounce
metrics:
  duration: "~18 minutes"
  completed_date: "2026-03-26"
  tasks_completed: 2
  files_changed: 5
---

# Phase 04 Plan 02: FormattingService and Coordinator Methods Summary

FormattingService enum with 4 static UITextInput-based operations plus Coordinator delegation wiring, with 14 unit tests covering ASCII, emoji, CRLF, undo atomicity, and redo.

## What Was Built

### FormattingService.swift (new)

Pure formatting logic extracted as a testable enum. All four operations use UITextInput protocol exclusively — never `textStorage`. Each operation:
1. Saves `selectedRange` before any modification
2. Calls `beginUndoGrouping()` before first text change
3. Uses `textView.replace(_:withText:)` for selection-based operations
4. Uses `textView.insertText(_:)` for cursor-only operations
5. Calls `endUndoGrouping()` and `setActionName()` after last text change
6. Restores `selectedRange` with recalculated offsets

A private `UITextView` extension provides `uiTextRange(from:)` to bridge `NSRange` to `UITextRange` (required because `UITextRange` cannot be constructed directly).

### MarkdownTextEditor.swift (modified)

- Added `weak var textView: UITextView?` to `Coordinator`
- Assigned `context.coordinator.textView = tv` in `makeUIView` after delegate assignment
- Added four public methods: `applyBold()`, `applyItalic()`, `applyBullet()`, `insertTable()` — each delegates to `FormattingService` and calls `text = tv.text` to sync the SwiftUI binding

### Test Coverage

**FormattingOperationsTests (9 tests — all pass):**
- Bold wraps selection, inserts at cursor, handles emoji (UTF-16 boundary safe)
- Italic wraps selection, inserts at cursor
- Bullet prefixes line, handles CRLF line endings
- Table inserts template at cursor, replaces selection

**UndoRedoTests (5 tests — all pass):**
- Undo reverts bold insertion
- canUndo is false on fresh UITextView
- Bold wrapping is atomic (one undo undoes both markers)
- Redo re-applies formatting after undo
- canRedo is false when no undo performed

## Commits

- `dbf77c3` — feat(04-02): create FormattingService with bold, italic, bullet, table operations
- `fcac321` — feat(04-02): extend Coordinator with formatting methods + fix UndoRedoTests

## Verification

```
FormattingOperationsTests: 9/9 PASSED
UndoRedoTests: 5/5 PASSED
MarkdownHighlighterTests: 5/5 PASSED (unchanged)
UnsavedChangesTests: 3/3 PASSED (unchanged)
```

No direct `textStorage` usage in `FormattingService.swift` (confirmed by grep).

## Deviations from Plan

None — plan executed exactly as written.

The TDD process note: both test suites went directly GREEN rather than RED first because `FormattingService.swift` was created in the same pass as the test updates. The RED state would have been a compile error (missing type) rather than a test failure.

## Ready for Plan 04-03

`EditorView` can now wire toolbar buttons to:
```swift
coordinator.applyBold()
coordinator.applyItalic()
coordinator.applyBullet()
coordinator.insertTable()
```
The `weak var textView` reference is set on `makeUIView`, so calls are safe as long as the UITextView is alive.

## Self-Check: PASSED
