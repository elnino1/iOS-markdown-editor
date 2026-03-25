# iOS Markdown Editor

## What This Is

A free iOS app for editing markdown files from any location — local storage, iCloud, Google Drive, or any cloud provider. Users open files via the in-app file picker or by using "Open With" from another app (e.g. Google Drive), edit them with a raw text editor, and save changes back to the original location. Designed initially for personal use, with potential App Store distribution later.

## Core Value

A focused markdown editor that works with any file source — open from anywhere, edit, save back. No account required, no lock-in.

## Requirements

### Validated

- [x] User can open a markdown file using the in-app file picker — Validated in Phase 01: Foundation
- [x] User can open a markdown file via "Open With" from another app (Google Drive, Files, etc.) — Validated in Phase 01: Foundation
- [x] User can edit the opened file as raw text — Validated in Phase 01: Foundation
- [x] User can save edits back to the original file location — Validated in Phase 01: Foundation

### Active

- [ ] Editor shows a visual indicator when there are unsaved changes
- [ ] Editor applies markdown syntax coloring
- [ ] App supports light and dark mode

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
*Last updated: 2026-03-25 — Phase 01 complete: open-edit-save loop fully implemented*
