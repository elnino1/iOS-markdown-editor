# iOS Markdown Editor

## What This Is

A free iOS app for editing markdown files stored in Google Drive. It lets users browse their full Drive folder hierarchy — including dot folders (e.g. `.claude`, `.planning`) — open markdown files, edit them with a raw text editor and formatting toolbar, and save changes back to Drive. Designed initially for personal use, with potential App Store distribution later.

## Core Value

Users can browse, edit, and save markdown files anywhere in their Google Drive — including dot folders that other apps hide.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] User can browse Google Drive folder hierarchy, including folders starting with `.`
- [ ] User can open a markdown file from any folder in Drive
- [ ] User can edit the file with a raw text editor
- [ ] User can format text via toolbar: bold, italic, headers, bullet lists, numbered lists
- [ ] User can save edits back to Google Drive

### Out of Scope

- Markdown preview / rendered output — deferred to v2
- WYSIWYG editing — deferred to v2
- Local file storage — Drive-only for now
- Note-taking / organizational features — this is an editor, not a notes app
- App Store publishing — personal use first, distribution later if promising

## Context

- Existing apps like "Markdown Pro" fail this use case because they filter out dot folders, making them unusable for workflows that store config/planning files in Drive (e.g. `.claude/`, `.planning/`)
- The app is greenfield, built for iOS using Swift/SwiftUI
- Google Drive API (or Files app integration via UIDocumentPickerViewController) will be needed for folder browsing and file access
- Free app — no monetization requirements for v1

## Constraints

- **Platform**: iOS only — no macOS/iPadOS parity required for v1
- **Cost**: Free — no paid APIs or subscriptions that would require a backend
- **Scope**: Simple — avoid feature creep; editing workflow is the only goal

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Raw editor for v1 (no preview) | Simpler to build; preview is v2 | — Pending |
| Google Drive as storage backend | User's files live there; no local storage needed | — Pending |

---
*Last updated: 2026-03-25 after initialization*
