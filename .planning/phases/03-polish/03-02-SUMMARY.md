---
phase: 03-polish
plan: 02
subsystem: large-file-and-encoding-warnings
tags: [edge-cases, ux, alerts, highlighting, encoding]
dependency_graph:
  requires: [03-01]
  provides: [large-file-warning, encoding-fallback-warning]
  affects: [MarkdownDocument, AppState, EditorView, MarkdownTextEditor]
tech_stack:
  added: []
  patterns: [usedEncodingFallback flag on UIDocument subclass, @Published Bool warning flags, SwiftUI @State local alert gates, UIViewRepresentable parameter for feature toggle]
key_files:
  created: []
  modified:
    - MarkdownEditor/MarkdownDocument.swift
    - MarkdownEditor/AppState.swift
    - MarkdownEditor/EditorView.swift
    - MarkdownEditor/MarkdownTextEditor.swift
decisions:
  - "highlightingDisabled is @State in EditorView (not derived from largeFileWarning) so dismissing the alert does not re-enable highlighting for the session"
  - "onChange(isEditorPresented) resets highlightingDisabled on new session; largeFileWarning onChange fires after and re-disables if needed — correct ordering guaranteed by Swift main-actor batching"
  - "MarkdownTextEditor coordinator carries isHighlightingEnabled var updated via updateUIView to guard debounce highlight during live typing"
metrics:
  duration_seconds: 338
  completed_date: "2026-03-26"
  tasks_completed: 2
  tasks_total: 2
  files_modified: 4
---

# Phase 03 Plan 02: Large-File and Encoding Warnings Summary

Large files open without syntax highlighting jank; non-UTF-8 files surface a one-time encoding notice — using a usedEncodingFallback flag, two @Published warning bools, and decoupled @State alert triggers in EditorView.

## What Was Built

- `MarkdownDocument.usedEncodingFallback: Bool` — set in `load(fromContents:)`: `true` when isoLatin1 fallback was used, `false` for UTF-8 files; cleared on each load
- `AppState.largeFileWarning: @Published Bool` — set to `true` in `_openDirectly` success branch when `doc.text.utf8.count > 512_000`
- `AppState.encodingFallbackWarning: @Published Bool` — set to `true` when `doc.usedEncodingFallback` is true after open
- Both flags reset to `false` in `closeCurrentDocument` Task block
- `MarkdownTextEditor.isHighlightingEnabled: Bool` parameter (default `true`) — `updateUIView` renders plain text with `UIFont.monospacedSystemFont` when false; `Coordinator.textViewDidChange` skips debounce highlight when false
- `EditorView` @State vars: `highlightingDisabled`, `showLargeFileAlert`, `showEncodingAlert`
- `EditorView` onChange handlers: `largeFileWarning` sets `highlightingDisabled = true` + `showLargeFileAlert = true`; `encodingFallbackWarning` sets `showEncodingAlert = true`; `isEditorPresented` resets `highlightingDisabled = false` on new session
- `EditorView` "Large File" alert — shown once per session, does not re-enable highlighting on dismiss
- `EditorView` "Encoding Changed" alert — one-time notice that file will be saved as UTF-8

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Coordinator did not respect isHighlightingEnabled during live typing**
- **Found during:** Task 2
- **Issue:** The plan's `updateUIView` guard only covered external text updates. The Coordinator's `textViewDidChange` debounce timer would still call `HighlightingService.applyMarkdownColors` for every keystroke even when highlighting was disabled.
- **Fix:** Added `isHighlightingEnabled: Bool` to `Coordinator`; synced from `updateUIView` via `context.coordinator.isHighlightingEnabled = isHighlightingEnabled`; added `guard isHighlightingEnabled else { return }` in `textViewDidChange`
- **Files modified:** `MarkdownEditor/MarkdownTextEditor.swift`
- **Commit:** 0d78ad0

**2. [Rule 2 - Missing critical functionality] No per-session reset for highlightingDisabled on new file open**
- **Found during:** Task 2
- **Issue:** When a user closes a large file and opens a normal file, `highlightingDisabled` would remain `true` since the plan only described setting it, not clearing it across sessions. The plan mentioned "reset until the file closes" without providing a concrete implementation.
- **Fix:** Added `.onChange(of: appState.isEditorPresented) { isPresented in if isPresented { highlightingDisabled = false } }` — fires before `largeFileWarning` onChange so the subsequent large-file check can correctly re-disable if the new file is also large
- **Files modified:** `MarkdownEditor/EditorView.swift`
- **Commit:** 0d78ad0

## Self-Check

**Files exist:**
- FOUND: MarkdownEditor/MarkdownDocument.swift
- FOUND: MarkdownEditor/AppState.swift
- FOUND: MarkdownEditor/EditorView.swift
- FOUND: MarkdownEditor/MarkdownTextEditor.swift

**Commits exist:**
- FOUND: 35ec066 (Task 1)
- FOUND: 0d78ad0 (Task 2)

## Self-Check: PASSED
