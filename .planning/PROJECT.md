# iOS Markdown Editor

## What This Is

A free iOS app for editing markdown files from any location — local storage, iCloud, Google Drive, or any cloud provider. Users open files via the in-app file picker or by using "Open With" from another app (e.g. Google Drive), edit them with a raw text editor, and save changes back to the original location. Designed initially for personal use, with potential App Store distribution later.

## Core Value

A focused markdown editor that works with any file source — open from anywhere, edit, save back. No account required, no lock-in.

## Current Milestone: v1.1 Formatting Toolbar

**Goal:** Add a keyboard-docked formatting toolbar so users can apply markdown syntax without typing manually.

**Target features:**
- Bold / italic buttons that wrap selected text (or insert at cursor)
- Bullet list button that prefixes the current line with `- `
- Table insertion button that inserts a default 3-column × 2-row markdown table
- Undo / Redo buttons backed by the system UITextView UndoManager

## Requirements

### Validated

- ✓ User can open a markdown file using the in-app file picker — Phase 1
- ✓ User can open a markdown file via "Open With" from another app — Phase 1
- ✓ User can edit the opened file as raw text — Phase 1
- ✓ User can save edits back to the original file location — Phase 1
- ✓ Editor shows a visual indicator when there are unsaved changes — Phase 2
- ✓ Editor applies markdown syntax coloring — Phase 2
- ✓ App supports light and dark mode — Phase 2
- ✓ Error handling for open/save failures — Phase 3
- ✓ Large file warning with highlighting fallback — Phase 3
- ✓ Recently opened files list — Phase 3

### Active

_(no active requirements — v1.1 milestone complete)_

### Validated in Phase 4: Formatting Toolbar

- ✓ Formatting toolbar appears above the keyboard while editing — Phase 4
- ✓ Bold button wraps selected text in `**markers**` (or inserts at cursor if no selection) — Phase 4
- ✓ Italic button wraps selected text in `*markers*` (or inserts at cursor if no selection) — Phase 4
- ✓ Bullet list button prefixes the current line with `- ` — Phase 4
- ✓ Table button inserts a 3-column × 2-row markdown table template at the cursor — Phase 4
- ✓ Undo button triggers system undo on the text view — Phase 4
- ✓ Redo button triggers system redo on the text view — Phase 4

### Out of Scope

- Markdown preview / rendered output — deferred to v2
- Formatting toolbar (bold, italic, headers, lists) — deferred to v2
- WYSIWYG editing — deferred to v2+
- Built-in Google Drive browser — user browses in Google Drive app, then "Open With"
- Google OAuth / Drive API integration — not needed with document-sharing approach
- Real-time collaboration — out of scope
- Note-taking / organizational features — this is an editor, not a notes app
- App Store publishing — personal use first, distribution later if promising

## Context

- Primary use case: editing markdown files stored in Google Drive (e.g. `.claude/`, `.planning/` folders). User browses in the Google Drive app which shows all folders including dot folders, then opens the file in this editor via "Open With".
- Existing apps like "Markdown Pro" fail this use case because they hide dot folders. This app sidesteps that by delegating browsing to the source app.
- The app uses iOS document sharing (UIDocument + UIDocumentPickerViewController) — no cloud API integration needed.
- Greenfield iOS app built with Swift/SwiftUI.
- Free app — no monetization requirements for v1.

## Constraints

- **Platform**: iOS only — no macOS/iPadOS parity required for v1
- **Cost**: Free — no paid APIs, no backend required
- **Scope**: Simple editor — open, edit, save. Nothing more.
- **No auth required**: Document sharing handles file access; no login screen needed

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Document sharing instead of Drive API | Simpler, supports all file sources, no OAuth needed | ✓ Approved |
| Raw editor for v1 (no preview) | Simpler to build; validates core value first | ✓ Approved |
| UIDocument for file coordination | iOS standard for read/write back to original location | ✓ Implemented |

---
*Last updated: 2026-03-27 — Phase 4 complete: formatting toolbar shipped. v1.1 milestone complete.*
