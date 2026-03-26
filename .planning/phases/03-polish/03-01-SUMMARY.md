---
phase: 03-polish
plan: 01
subsystem: error-handling
tags: [error-handling, alerts, ux, file-operations]
dependency_graph:
  requires: [01-01, 01-02, 01-03]
  provides: [file-error-surfacing]
  affects: [AppState, HomeView, EditorView]
tech_stack:
  added: []
  patterns: [SwiftUI .alert with Binding<Bool>, FileOperationError Identifiable enum, CocoaError classification]
key_files:
  created: []
  modified:
    - MarkdownEditor/AppState.swift
    - MarkdownEditor/HomeView.swift
    - MarkdownEditor/EditorView.swift
decisions:
  - "UIDocument.open does not expose an error property publicly; open failure surfaces as .unknown rather than a classified error"
  - "Try Again in HomeView alert routes through both simulator (DocumentPickerPresenter) and device (.fileImporter) paths"
  - "Save Failed alert placed on NavigationStack after Unsaved Changes alert using SwiftUI multi-alert chaining"
metrics:
  duration_seconds: 363
  completed_date: "2026-03-26"
  tasks_completed: 2
  tasks_total: 2
  files_modified: 3
---

# Phase 03 Plan 01: Error Alerts Summary

Surface file operation errors to the user via three typed alert dialogs instead of silent drops or console prints.

## What Was Built

- `FileOperationError` enum with 5 typed cases (`permissionDenied`, `fileNotFound`, `unreadable`, `saveFailed`, `unknown`) and user-friendly `.message` strings
- `static func from(_:)` factory mapping `CocoaError` codes to typed cases
- `@Published var openError: FileOperationError?` in `AppState` — set on `UIDocument.open` failure
- `HomeView` `.fileImporter` `.failure` branch now sets `appState.openError` instead of silent `print`
- `HomeView` `.alert` driven by `appState.openError` with **Try Again** (reopens picker, handles both simulator and real device paths) and **Cancel**
- `EditorView` `saveImmediately` checks the `Bool` success parameter and sets `showSaveError = true` on failure
- `EditorView` dismiss-only "Save Failed" `.alert` using `FileOperationError.saveFailed.message`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] UIDocument.error does not exist as a public API**
- **Found during:** Task 1
- **Issue:** Plan specified `doc.error.map { FileOperationError.from($0) } ?? .unknown` but `UIDocument` has no public `.error` property in the iOS SDK
- **Fix:** Replaced with `self.openError = .unknown` — open failures always surface as `.unknown` since `UIDocument.open` provides no error details through its callback
- **Files modified:** `MarkdownEditor/AppState.swift`
- **Commit:** 004a4e7

## Self-Check

**Files exist:**
- FOUND: MarkdownEditor/AppState.swift
- FOUND: MarkdownEditor/HomeView.swift
- FOUND: MarkdownEditor/EditorView.swift

**Commits exist:**
- FOUND: 004a4e7 (Task 1)
- FOUND: 5d8065b (Task 2)

## Self-Check: PASSED
