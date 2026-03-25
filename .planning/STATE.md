# Project State: iOS Markdown Editor

**Project:** iOS Markdown Editor with Google Drive Integration
**Core Value:** Users can browse, edit, and save markdown files anywhere in Google Drive — including dot folders that other apps hide.

**Initialized:** 2026-03-25

---

## Current Position

**Milestone:** Roadmap
**Current Phase:** Not yet started
**Current Plan:** None
**Overall Progress:** 0/11 requirements complete

```
[                    ] 0%
```

---

## Focus

**This session:** Create roadmap from 11 v1 requirements
**Next session:** `/gsd:plan-phase 1` — Plan Phase 1 Foundation (Auth)

---

## Project Reference

| Field | Value |
|-------|-------|
| **Core Value** | Users can browse, edit, and save markdown files anywhere in Google Drive — including dot folders that other apps hide |
| **Platform** | iOS (Swift/SwiftUI) |
| **Backend** | Google Drive REST API v3 |
| **Auth** | Google OAuth 2.0 |
| **Scope (v1)** | Authentication, file browsing (including dot folders), raw text editing, formatting toolbar, save to Drive |
| **Out of Scope (v1)** | Markdown preview, WYSIWYG, offline editing, other cloud storage, real-time collaboration |
| **Constraints** | Free app, iOS only, no local file storage, simple editing workflow |
| **Status** | In planning |

---

## Roadmap Status

**Phases Defined:** 5
- Phase 1: Foundation (Google OAuth + Drive API)
- Phase 2: Browse (Folder hierarchy with dot folders)
- Phase 3: Edit (Raw text editor, toolbar, appearance)
- Phase 4: Sync (Save to Drive with conflict detection)
- Phase 5: Polish (Edge cases and refinements)

**Requirements Coverage:** 11/11 mapped ✓

**Next:** Plan Phase 1

---

## Architecture Overview

**Stack (from research):**
- Swift 5.10+, SwiftUI, iOS 17.0+ target (iOS 16.0 minimum)
- Google Drive REST API v3 + GoogleSignIn SDK 7.0+
- Keychain for token storage
- SwiftData (iOS 17+) or Core Data for app state

**Major Components (delivery order):**
1. AuthManager — OAuth token lifecycle, refresh, Keychain storage
2. DriveManager — Drive API calls for file/folder listing
3. DriveFileCache — Metadata caching
4. BrowseViewController — Hierarchical folder tree UI
5. TextEditorViewController — Raw text editing
6. EditorState (ViewModel) — File context coordination
7. SyncManager — Upload with ETag-based conflict detection
8. ConflictResolver — User choice UI for save conflicts

---

## Critical Pitfalls to Avoid

From research/SUMMARY.md:

1. **OAuth Token Expiration** — Auto-refresh required, test manual token expiration
2. **File Conflict on Save** — ETag-based detection with user choice dialog
3. **Dot Folder Access Denied** — Custom Drive API browser (not UIDocumentPickerViewController)
4. **Large File / Network Timeout** — Resumable uploads with 30+ second timeout
5. **State Management After Backgrounding** — Refresh metadata on foreground

---

## Key Decisions Made

| Decision | Rationale | Owner | Status |
|----------|-----------|-------|--------|
| Raw editor for v1 (no preview) | Simpler, validates core value first | Project | ✓ Approved |
| Google Drive as storage backend | User's files live there, no local sync | Project | ✓ Approved |
| Custom Drive API browser | Enables dot-folder access (differentiator) | Research | ✓ Validated |
| OAuth 2.0 PKCE flow | Security best practice, AppReview compatible | Research | ✓ Recommended |
| ETag-based conflict detection | Prevents silent data loss | Research | ✓ Recommended |
| UITextView wrapping if needed | Better performance on large files (>100KB) | Research | Deferred to Phase 3 |

---

## Session Notes

### Initialization (2026-03-25)

**Actions:**
- Read PROJECT.md — confirmed core value and constraints
- Read REQUIREMENTS.md — extracted 11 v1 requirements across 4 categories
- Read research/SUMMARY.md — loaded phase structure recommendation and pitfalls
- Read config.json — noted "coarse" granularity (compress to 3-5 phases)
- Created roadmap with 5 phases (justified: natural workflow boundaries override coarse guidance)

**Decisions:**
- Phase structure: Foundation → Browse → Edit → Sync → Polish (dependency-driven)
- Coverage: 11/11 requirements mapped, zero orphans
- Success criteria: 4-5 observable user behaviors per phase
- Files: ROADMAP.md, STATE.md created; REQUIREMENTS.md traceability updated

**Blockers:** None

**Next:** Plan Phase 1

---

## Accumulated Todos

- [ ] Phase 1 Plan: Map Foundation phase to executable tasks
- [ ] Phase 1 Implementation: Build Google OAuth + token refresh
- [ ] Phase 1 Verification: Test token lifecycle (expiration, refresh, recovery)
- [ ] Phase 2 Plan: Map Browse phase tasks
- [ ] Phase 2 Implementation: Build folder browser with dot-folder support
- [ ] Phase 3 Plan: Map Edit phase tasks
- [ ] Phase 4 Plan: Map Sync phase tasks
- [ ] Phase 5 Plan: Map Polish phase tasks

---

## Performance Metrics

**Roadmap Quality:**
- Requirement coverage: 11/11 (100%) ✓
- Orphaned requirements: 0 ✓
- Phase dependencies: Linear → clear execution order ✓
- Success criteria: Observable and measurable ✓

**Estimated Effort (from granularity):**
- Coarse granularity suggests 3-5 phases; 5 phases used (justified by workflow dependencies)
- Per-phase complexity: Medium (OAuth + Drive API integration, custom UI, conflict resolution)

---

*State initialized: 2026-03-25*
*Last updated: 2026-03-25*
