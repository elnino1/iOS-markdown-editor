---
phase: 03-polish
plan: 03
subsystem: recent-files
tags: [ux, persistence, usertdefaults, bookmarks, list-ui]
dependency_graph:
  requires: [03-01, 03-02]
  provides: [recent-files-store, recent-files-ui]
  affects: [RecentFilesStore, AppState, HomeView]
tech_stack:
  added: []
  patterns: [security-scoped bookmarks for persistent URL references, UserDefaults array of JSON-encoded entries, ObservableObject with @Published entries array, SwiftUI List with Section headers and onDelete]
key_files:
  created:
    - MarkdownEditor/RecentFilesStore.swift
  modified:
    - MarkdownEditor/AppState.swift
    - MarkdownEditor/HomeView.swift
    - MarkdownEditor.xcodeproj/project.pbxproj
decisions:
  - "Bookmark-based persistence (not raw URLs) so entries survive security scope changes and app restarts"
  - "Best-effort dedup by filename (not by URL) to handle files moved or renamed outside the app"
  - "recentFiles accessed via appState.recentFiles (not a separate @EnvironmentObject injection) since HomeView already has @EnvironmentObject appState"
  - "openFilePicker() extracted as private func to deduplicate simulator/device branching across empty-state and list-view buttons"
metrics:
  duration_seconds: 256
  completed_date: "2026-03-26"
  tasks_completed: 2
  tasks_total: 2
  files_modified: 4
---

# Phase 03 Plan 03: Recent Files Summary

UserDefaults-backed RecentFilesStore with bookmark-based URL persistence (10-item limit) wired into AppState and rendered as a SwiftUI List section in HomeView with swipe-to-delete and tap-to-reopen.

## What Was Built

- `RecentFilesStore`: `@MainActor final class` with `@Published private(set) var entries: [RecentFileEntry]`; methods `add(url:)`, `remove(at:)`, `resolve(_:)`; persists to `UserDefaults.standard` under key `"recentFilesBookmarks"` as an array of JSON-encoded entries
- `RecentFileEntry`: `Identifiable, Codable` struct with `id: UUID`, `filename: String`, `bookmark: Data?`, `fallbackURL: URL`, `lastOpenedAt: Date`
- `AppState.recentFiles = RecentFilesStore()` — instantiated as a plain `let` property
- `_openDirectly` success branch calls `self.recentFiles.add(url: url)` after every successful open
- `HomeView` restructured with `Group { if empty → emptyStateView; else → recentFilesListView }`
- `emptyStateView` — identical to previous empty state; unchanged layout
- `recentFilesListView` — `List` with two sections: "Open Other File..." button row + "Recent" section with `ForEach` rows showing filename and `Text(entry.lastOpenedAt, style: .relative)`, with `.onDelete` for swipe-to-delete
- `openFilePicker()` private func deduplicates the `#if targetEnvironment(simulator)` branching used by both the empty-state button and the "Open Other File..." row and the Try Again alert button
- All 9 existing tests pass: TEST SUCCEEDED

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check

**Files exist:**
- FOUND: MarkdownEditor/RecentFilesStore.swift
- FOUND: MarkdownEditor/AppState.swift
- FOUND: MarkdownEditor/HomeView.swift

**Commits exist:**
- FOUND: 56ea333 (Task 1)
- FOUND: 25cc243 (Task 2)

## Self-Check: PASSED
