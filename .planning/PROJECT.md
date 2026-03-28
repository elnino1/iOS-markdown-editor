# iOS Markdown Editor

## What This Is

A free iOS app for editing markdown files from any location — local storage, iCloud, Google Drive, or any cloud provider. Users open files via the in-app file picker or by using "Open With" from another app (e.g. Google Drive), edit them with a raw text editor with a formatting toolbar, and save changes back to the original location. Designed for personal use, with potential App Store distribution later.

## Core Value

A focused markdown editor that works with any file source — open from anywhere, edit, save back. No account required, no lock-in.

## Current Milestone: v1.2 Markdown Preview

**Goal:** Add a reading mode so users can view rendered markdown instead of raw syntax.

**Target features:**
- Toggle button in the editor nav bar to switch between edit and preview modes
- Full markdown rendering: headings, bold/italic, lists, code blocks, tables, links
- WKWebView-based renderer for complete fidelity
- Links open in SFSafariViewController (in-app browser)
- Light/dark mode support in preview

## Current State

**Shipped:** v1.1 (2026-03-27)
**Codebase:** ~1,610 lines Swift
**Tech stack:** UIDocument, UITextView (UIViewRepresentable), UIToolbar (inputAccessoryView), NSUndoManager, HighlightingService (regex)
**Test coverage:** 30 unit tests (16 formatting ops + 5 undo/redo + 2 toolbar visual + 5 highlighting + 3 unsaved indicator)

## Requirements

### Validated

- ✓ User can open a markdown file using the in-app file picker — v1.0
- ✓ User can open a markdown file via "Open With" from another app — v1.0
- ✓ User can edit the opened file as raw text — v1.0
- ✓ User can save edits back to the original file location — v1.0
- ✓ Editor shows a visual indicator when there are unsaved changes — v1.0
- ✓ Editor applies markdown syntax coloring — v1.0
- ✓ App supports light and dark mode — v1.0
- ✓ Error handling for open/save failures — v1.0
- ✓ Large file warning with highlighting fallback — v1.0
- ✓ Recently opened files list — v1.0
- ✓ Formatting toolbar appears above the keyboard while editing — v1.1
- ✓ Bold/italic buttons wrap selected text (or insert at cursor); toggle off when already formatted — v1.1
- ✓ Bullet list button prefixes the current line with `- `; toggles off if already bulleted — v1.1
- ✓ Table button inserts a 3-column × 2-row markdown table template — v1.1
- ✓ Undo/Redo buttons backed by system NSUndoManager — v1.1

### Active

- [ ] Toggle between edit and preview mode via nav bar button
- [ ] Preview renders headings, bold, italic, lists, code blocks, tables, links
- [ ] Links open in SFSafariViewController
- [ ] Preview respects light/dark mode

### Out of Scope

- WYSIWYG editing — tap preview to edit inline, deferred to v2+
- WYSIWYG editing — deferred to v2+
- Header buttons (H1/H2/H3) in toolbar — deferred
- Built-in Google Drive browser — user browses in Google Drive app, then "Open With"
- Google OAuth / Drive API integration — not needed with document-sharing approach
- Real-time collaboration — out of scope
- Note-taking / organizational features — this is an editor, not a notes app
- App Store publishing — personal use first, distribution later if promising

## Context

- Primary use case: editing markdown files stored in Google Drive (e.g. `.claude/`, `.planning/` folders). User browses in the Google Drive app which shows all folders including dot folders, then opens the file in this editor via "Open With".
- Existing apps like "Markdown Pro" fail this use case because they hide dot folders. This app sidesteps that by delegating browsing to the source app.
- The app uses iOS document sharing (UIDocument + UIDocumentPickerViewController) — no cloud API integration needed.
- Built with Swift/SwiftUI + UIKit bridge layer. iOS 26 simulator has a file picker callback bug (tested on real device instead).
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
| UITextView over SwiftUI TextEditor | UIViewRepresentable gives access to UITextView internals needed for toolbar + undo | ✓ Implemented |
| UITextInput protocol for formatting ops | Never mutate textStorage directly — preserves undo stack integrity | ✓ Implemented |
| inputAccessoryView for toolbar | iOS standard keyboard-docked toolbar pattern; disappears with keyboard automatically | ✓ Implemented |
| Toggle-off formatting | Tapping bold/italic/bullet on already-formatted text strips markers (better UX) | ✓ Implemented |

---
*Last updated: 2026-03-27 — v1.2 Markdown Preview milestone started*
