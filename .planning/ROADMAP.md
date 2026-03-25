# Roadmap: iOS Markdown Editor

**Project:** iOS Markdown Editor with Google Drive Integration
**Core Value:** Users can browse, edit, and save markdown files anywhere in Google Drive — including dot folders that other apps hide.

**Created:** 2026-03-25
**Version:** 1.0
**Status:** Planning

---

## Phases

- [ ] **Phase 1: Foundation** - Google OAuth authentication and Drive API connection
- [ ] **Phase 2: Browse** - Hierarchical folder browsing including dot folders
- [ ] **Phase 3: Edit** - Raw text editing with formatting toolbar and appearance support
- [ ] **Phase 4: Sync** - Save changes back to Google Drive with conflict detection
- [ ] **Phase 5: Polish** - Edge cases, network error handling, and optional enhancements

---

## Phase Details

### Phase 1: Foundation

**Goal:** Enable secure Google authentication and establish Drive API connection with token lifecycle management

**Depends on:** Nothing (first phase)

**Requirements Mapped:** AUTH-01, AUTH-02, AUTH-03

**Success Criteria** (what must be TRUE when this phase completes):
1. User can sign in with their Google account using OAuth 2.0 and the app securely stores the authorization token
2. User stays signed in across app restarts (token persisted in Keychain)
3. User can sign out, clearing credentials and returning to login screen
4. App automatically refreshes expired tokens without user intervention (user can continue using app through token expiration event)

**Plan:** TBD

---

### Phase 2: Browse

**Goal:** Enable users to browse their complete Google Drive folder hierarchy, including dot-prefixed folders, and navigate to any markdown file

**Depends on:** Phase 1 (requires authenticated Drive access)

**Requirements Mapped:** BROW-01, BROW-02, BROW-03

**Success Criteria** (what must be TRUE when this phase completes):
1. User can see Google Drive root folder and navigate into subfolders, including folders starting with `.` (e.g. `.claude`, `.planning`)
2. User can drill down through nested folder hierarchies and see breadcrumb showing current path
3. Folder listings show only `.md` markdown files (but folders are always visible regardless of name)
4. User can refresh folder listing to see external Drive changes
5. App efficiently caches metadata to minimize API quota consumption

**Plan:** TBD

---

### Phase 3: Edit

**Goal:** Enable users to open and edit markdown files with a raw text editor, formatting toolbar, and appearance support

**Depends on:** Phase 2 (requires ability to open files from browser)

**Requirements Mapped:** EDIT-01, EDIT-03, EDIT-04, APPR-01

**Success Criteria** (what must be TRUE when this phase completes):
1. User can open a markdown file from the browser and edit it as raw text with full cursor control and system undo/redo
2. User can apply markdown formatting via toolbar buttons: bold, italic, headers (h1-h3), bullet lists, numbered lists (each inserts correct markdown syntax at cursor)
3. App displays "unsaved changes" indicator (e.g. asterisk in title or badge) when file has been edited since last save
4. App displays file metadata (path, size, last modified time) for context
5. App supports light and dark mode with proper appearance throughout editing interface

**Plan:** TBD

---

### Phase 4: Sync

**Goal:** Enable users to save changes back to Google Drive with conflict detection and reliable upload handling

**Depends on:** Phase 3 (requires edited file content to save)

**Requirements Mapped:** EDIT-02

**Success Criteria** (what must be TRUE when this phase completes):
1. User can save edits back to the original file in Google Drive with a single action
2. App implements ETag-based conflict detection: if file was modified externally while user was editing, app alerts user with choices ("Overwrite Server", "Discard Changes", "Save as New")
3. App shows sync status indicator during save operation (e.g. "Saving...", "Saved", error states)
4. App implements exponential backoff retry logic for transient failures and quota exhaustion
5. App handles large file uploads with resumable upload capability to survive network interruptions

**Plan:** TBD

---

### Phase 5: Polish

**Goal:** Handle edge cases, improve reliability, and add optional enhancements for refined user experience

**Depends on:** Phase 4 (requires core workflow to be complete)

**Requirements Mapped:** (none mandatory for v1; phase available for scope)

**Success Criteria** (what must be TRUE when this phase completes):
1. App displays meaningful error messages (e.g. "Permission denied: you don't have write access to this folder") instead of generic errors
2. App detects offline state and disables save operations with offline indicator
3. App refreshes file metadata when returning from background to detect external changes
4. App handles edge cases: non-UTF-8 file encoding, file size limits (warns on >5MB), special characters in filenames
5. App includes optional enhancements if time permits: keyboard shortcuts (⌘B, ⌘I, ⌘Z), find/replace, syntax highlighting

**Plan:** TBD

---

## Progress Tracking

| Phase | Goal | Requirements | Status | Completed |
|-------|------|--------------|--------|-----------|
| 1 - Foundation | OAuth + Drive API | 3 (AUTH-01, AUTH-02, AUTH-03) | Not started | - |
| 2 - Browse | Folder hierarchy | 3 (BROW-01, BROW-02, BROW-03) | Not started | - |
| 3 - Edit | Raw text editor | 4 (EDIT-01, EDIT-03, EDIT-04, APPR-01) | Not started | - |
| 4 - Sync | Save to Drive | 1 (EDIT-02) | Not started | - |
| 5 - Polish | Edge cases | 0 (optional) | Not started | - |

---

## Coverage Summary

**v1 Requirements:** 11 total
**Mapped to phases:** 11
**Unmapped (orphaned):** 0

✓ **100% requirement coverage validated**

---

## Dependency Graph

```
Phase 1: Foundation (Auth)
    ↓ (needs authenticated Drive access)
Phase 2: Browse (File discovery)
    ↓ (needs files to edit)
Phase 3: Edit (Text editing)
    ↓ (needs edited content)
Phase 4: Sync (Save to Drive)
    ↓ (optional)
Phase 5: Polish (Refinement)
```

This dependency order ensures:
- Token refresh logic (Phase 1) proven before any Drive calls (Phase 2-4)
- File browsing (Phase 2) validated before attempting to open and edit (Phase 3)
- Editing workflow (Phase 3) complete before implementing saves (Phase 4)
- Core workflow end-to-end before refining edge cases (Phase 5)

---

*Roadmap created: 2026-03-25*
*Based on: PROJECT.md, REQUIREMENTS.md, research/SUMMARY.md*
*Ready for planning: `/gsd:plan-phase 1`*
