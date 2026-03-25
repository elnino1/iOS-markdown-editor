# Project Research Summary

**Project:** iOS Markdown Editor with Google Drive Integration
**Domain:** iOS document editing app with cloud storage and dot-folder access
**Researched:** 2026-03-25
**Confidence:** MEDIUM (training data current to Feb 2025; recommend API/framework verification during Phase 1)

## Executive Summary

This is a focused iOS markdown editor that differentiates itself by enabling access to dot-prefixed folders in Google Drive (`.planning`, `.claude`, `.git`, etc.) — a feature explicitly blocked by standard iOS file pickers. The recommended approach combines SwiftUI for the frontend with direct Google Drive REST API integration via OAuth 2.0, avoiding the convenience but feature-limited `UIDocumentPickerViewController`.

Building this app requires careful attention to four critical areas: (1) OAuth token refresh and lifecycle management, (2) file conflict detection when concurrent edits occur, (3) explicit handling of dot-folder visibility in API queries, and (4) robust network error handling for save operations. The technology stack is mature and well-documented (Swift 5.10+, SwiftUI on iOS 16+, Google Drive REST API v3), but the integration complexity is moderate due to Google Drive's async APIs and the need for custom file browsing UI.

The roadmap should sequence Foundation → Browse → Edit → Sync → Polish, with each phase building upon the previous and each addressing specific pitfalls identified in research. V1 is explicitly a raw text editor (no markdown preview, no offline sync, no multi-file tabs) to validate the core value proposition and user workflow before expanding scope.

## Key Findings

### Recommended Stack

The technology stack emphasizes leveraging official Google SDKs and Apple frameworks to minimize dependencies and avoid reimplementing OAuth or file handling. Swift 5.10+ with SwiftUI (iOS 16+) is the standard for new iOS projects. Google Drive integration requires the official REST API v3 rather than `UIDocumentPickerViewController` to enable dot-folder browsing—a critical differentiator.

**Core technologies:**
- **Swift 5.10+ / SwiftUI** — Modern, declarative UI framework with strong FileProvider integration; reduces boilerplate vs. UIKit
- **Google Drive REST API v3 + GoogleSignIn SDK 7.0+** — Only way to access Google Drive directly with dot-folder support; UIDocumentPickerViewController only accesses iCloud Drive
- **URLSession (built-in)** — Sufficient for REST API calls; Combine reactive patterns for async callbacks
- **FileProvider framework** — Local caching for offline access; enables syncing changes back to Drive
- **SwiftData (iOS 17+) or Core Data** — Store OAuth tokens securely in Keychain; persist auth state, file history, user preferences (NOT markdown content, which lives in Drive)
- **UITextView (wrapped in SwiftUI)** — More performant than SwiftUI TextEditor for larger files; supports attributed strings for toolbar formatting. Acceptable to start with TextEditor if file sizes stay <100KB.

**Version constraints:**
- Minimum iOS 16.0 (SwiftUI TextEditor support)
- Target iOS 17.0+ (SwiftData available; cleaner async/await patterns)
- Xcode 15.1+

**Deferred to v2+:**
- Markdown parsers (cmark-swift, Down, SwiftMarkdown) — add for preview feature
- Syntax highlighting — nice-to-have, deferred
- Image/file embedding and rich media — scope expansion

### Expected Features

**Must-have (table stakes — no launch without these):**
- Google Drive OAuth2 authentication with token refresh
- Browse Drive folder hierarchy including dot-prefixed folders (`.claude`, `.planning`, etc.) — this is THE differentiator
- Open and edit markdown files as raw text
- Formatting toolbar: bold, italic, headers (h1-h3), bullets, numbered lists
- Save edits back to Drive atomically with conflict detection (ETag-based)
- File metadata display (path, size, last modified)
- Sync status indicator (saved / syncing / error states)

**Should-have (competitive, v1 if time permits):**
- Keyboard shortcuts (Command+B, Command+Z, Command+I) — increases perceived polish
- Find/Replace within file — useful for large documents
- Syntax highlighting — markdown color coding improves readability
- Undo/redo beyond system level — refined editing experience

**Explicitly defer to v2+:**
- Markdown preview / rendered output — explicitly out of v1 scope per PROJECT.md
- Local file caching for offline editing — requires complex sync and conflict resolution
- Multiple file tabs — single-file workflow for v1
- Real-time collaboration / multi-user editing — out of scope
- Custom themes or colors beyond system light/dark mode
- Note-taking features (notebooks, tags, search across files) — this is an editor, not a notes app

**Google Drive-specific MVP requirements:**
- Dot folder visibility (non-negotiable differentiator)
- Full path breadcrumb for deep folder navigation
- Refresh folder listing (Drive changes outside app)
- File picker fallback (UIDocumentPickerViewController as emergency UX)

### Architecture Approach

The recommended architecture uses a component-based approach with clear separation between UI (Views), business logic (ViewModels), and external integrations (Managers). The data flow follows a producer-consumer pattern: AuthManager produces valid tokens → DriveManager consumes tokens to fetch file metadata → FileSystemCoordinator maps cloud files to local paths → TextEditorViewController displays and edits → SyncManager saves changes back to Drive with conflict resolution.

**Major components and responsibilities:**
1. **AuthManager** — Google OAuth 2.0 lifecycle: token refresh, expiration handling, Keychain storage
2. **DriveManager** — Google Drive REST API calls for listing files/folders, fetching metadata; implements exponential backoff retry logic
3. **DriveFileCache** — In-memory metadata cache to minimize Drive API quota consumption; stores folder listings and file metadata (not content)
4. **BrowseViewController** — Hierarchical folder tree UI; allows drill-down to dot folders with no MIME type filtering
5. **FileSystemCoordinator** — Maps Drive file IDs to local temp file paths; manages cached file content on disk
6. **TextEditorViewController** — Raw markdown text editing, toolbar formatting controls
7. **EditorState (ViewModel)** — Current file context: file ID, name, version, unsaved changes flag; acts as mediator across views
8. **SyncManager** — Drive file uploads with ETag-based conflict detection; implements resumable uploads for reliability
9. **ConflictResolver** — Presents user choice when file changed externally: "Overwrite Server" | "Discard Changes" | "Save as New"

**Critical patterns:**
- All network calls implement exponential backoff retry with token refresh handling and graceful cache degradation
- EditorState coordinates between browse and edit views; holds authoritative file context
- Cache invalidation triggered post-upload and on explicit user refresh action
- File content stored on disk (not in memory) even for small files — keeps memory footprint predictable
- Authentication uses system browser (`ASWebAuthenticationSession`), never embedded webview (Apple AppReview requirement)

### Critical Pitfalls

1. **OAuth Token Expiration & Refresh Loop** — Users can't save mid-session if token expires without proper refresh handling. Prevent by: storing refresh tokens in Keychain, catching 401 responses and auto-refreshing, using GIDSignIn framework (handles automatically), testing manual token expiration scenarios. Must be correct before any Drive integration ships.

2. **File Conflict on Save (Concurrent Edits)** — Editing file in Drive web while app is open → app saves without checking current version → external edits silently lost with no recovery. Prevent by: implementing ETag-based conflict detection, showing user choice dialog ("Overwrite Server" | "Discard Changes" | "Save as New"), logging all save operations with timestamps. Essential before save feature ships.

3. **Dot Folder Access Denied** — Standard API queries filter out dot folders; UIDocumentPickerViewController won't show them → core value proposition completely broken. Prevent by: using custom Drive API browser (mandatory), not applying default "hide dotfiles" filters, explicitly testing with `.planning` and `.claude` folders in test Drive, documenting that system picker cannot access dot folders.

4. **Large File / Network Timeout During Save** — Saving >100KB markdown on slow network times out mid-stream with no resume capability → user loses unsaved edits. Prevent by: implementing Google Drive resumable uploads, setting 30+ second timeouts with exponential backoff, showing upload progress indicator, testing network slow-down and WiFi-to-cellular switches during save.

5. **State Management After App Backgrounding** — App returns from background with stale file state; external change made while backgrounded goes unnoticed → save overwrites external edits silently. Prevent by: implementing `sceneWillEnterForeground` handler to refresh file metadata, checking ETag/modification time when returning from background, alerting user if external change detected before allowing further edits.

## Implications for Roadmap

Based on research, the recommended phase structure follows dependency order: authentication must work before browsing, browsing before opening, opening before editing, editing before saving. This progression validates the core workflow at each step and isolates pitfalls to specific phases for focused mitigation.

### Phase 1: Foundation (Auth + Drive Connection)
**Rationale:** Google Drive integration and OAuth2 are prerequisites for all other features. Core pitfall (token refresh) must be correct before touching any file operations.
**Delivers:**
- Working Google Sign-In with OAuth 2.0 PKCE flow
- AuthManager with token lifecycle management and Keychain storage
- DriveManager with basic files.list capability
- Test auth flow end-to-end: sign in, token expiration, refresh, invalid token recovery
**Avoids:**
- Pitfall 1 (Token Expiration) — implement refresh logic and token storage correctly from start
- Pitfall 3 (Dot Folder Access) — verify Drive API returns dot folders with minimal filters
- Pitfall 6 (Insufficient OAuth Scope) — request `drive` scope for full Drive access

**Research flags:** Verify current GIDSignIn SDK behavior with Xcode 16 docs; confirm PKCE flow implementation; test dot-folder visibility in Drive API v3 with current credentials.

### Phase 2: Browse (Display Drive Hierarchy)
**Rationale:** Foundation auth enables building the custom file browser that differentiates this app. Folder browsing must work before opening files.
**Delivers:**
- BrowseViewController with hierarchical folder tree
- DriveFileCache for metadata (minimal API quota usage)
- FileSystemCoordinator mapping Drive IDs to local paths
- Full dot-folder support with no filters
- Breadcrumb navigation and refresh button
- End-to-end: browse from root, drill into `.planning` folder, see files inside
**Avoids:**
- Pitfall 3 (Dot Folder Access) — custom browser mandatory; don't use UIDocumentPickerViewController
- Pitfall 8 (Infinite Folder Recursion) — track visited folder IDs, limit depth to ~50 levels
**Features delivered:** Browse cloud storage hierarchy, dot folder browsing (differentiator)

**Research flags:** Verify exact Drive API query parameters for listing (confirm `trashed=false` includes dot folders); test with real shared Drive structures for folder loops.

### Phase 3: Edit (Open + Modify)
**Rationale:** With auth and browsing working, implement the core editing experience. Raw text editing is the minimal surface; toolbar follows if time permits.
**Delivers:**
- TextEditorViewController with UITextView or SwiftUI TextEditor
- EditorState ViewModel coordinating file context across views
- Text editing with cursor control and system undo/redo
- Formatting toolbar: bold, italic, headers (h1-h3), bullets, numbered lists — all insert markdown syntax
- Unsaved changes indicator
- File metadata display (path, size, modified time)
- End-to-end: open file from Phase 2 browser, edit text, see "unsaved changes" indicator
**Avoids:**
- Pitfall 9 (Markdown Formatting Corruption) — careful selection handling with UITextView APIs, test with special characters
- Pitfall 7 (Text Encoding Issues) — detect encoding on load (attempt UTF-8 first), always save UTF-8
**Features delivered:** Open markdown files, raw text editing, basic text formatting toolbar

**Research flags:** Validate TextEditor performance on 1MB+ files; if slow, fallback plan to switch to UITextView wrapper is documented in STACK.md. Test toolbar selection handling thoroughly with special chars.

### Phase 4: Sync (Save Back to Drive)
**Rationale:** File editing is worthless without saving. Conflict detection is essential for multi-access scenarios.
**Delivers:**
- SyncManager with Drive files.update API
- ETag-based conflict detection
- ConflictResolver UI: "Overwrite Server" | "Discard Changes" | "Save as New"
- Exponential backoff retry logic (quota exhaustion, transient failures)
- Resumable upload for large files
- Sync status indicator (saved / syncing / error states)
- End-to-end: edit file, tap Save, see confirmation; verify file updated in Drive web
**Avoids:**
- Pitfall 2 (File Conflict on Save) — implement ETag checking before every save; must support user choice for conflicts
- Pitfall 4 (Large File / Network Timeout) — resumable uploads, 30+ second timeout, progress indicator
- Pitfall 5 (State Management After Backgrounding) — refresh metadata on foreground, check ETag before allowing further edits
- Pitfall 10 (No Offline Support, Confusing UX) — disable save button when offline; show network indicator
**Features delivered:** Save to cloud, sync status indicator

**Research flags:** Confirm ETag availability and format in Google Drive API response; validate resumable upload implementation with slow network simulation; test background session behavior during save.

### Phase 5: Polish (Edge Cases & Refinement)
**Rationale:** Earlier phases deliver core workflow; this phase addresses UX edge cases and reliability.
**Delivers:**
- Network error handling and offline indicator
- File size limits with warnings (e.g., >5MB warning)
- Character encoding detection (non-UTF-8 file support)
- Cache invalidation on app foreground
- Keyboard shortcuts (Command+B, Command+Z, Command+I) if time permits
- Find/Replace within file if time permits
- Syntax highlighting if time permits
- Thorough error messages (not generic "Error 403")
- UX clarity: "This is a raw markdown editor. Formatting appears as markdown syntax."
**Avoids:**
- Pitfall 11 (Poor Error Messages) — specific messages like "Permission denied: you don't have write access" vs. generic errors
- Pitfall 12 (Toolbar UX Confusion) — clear UI communication that syntax is visible
**Features delivered:** Keyboard shortcuts (optional), find/replace (optional), syntax highlighting (optional), improved error handling

**Research flags:** Phase 5 is polish; research flags from Phases 1-4 should be resolved by here. Validate Network.framework availability for target iOS version.

### Phase Ordering Rationale

- **Auth before Browse:** Drive API calls require valid tokens; token refresh logic must be proven before adding network calls
- **Browse before Edit:** Users can't edit files they can't access; browser validates Drive API integration end-to-end
- **Edit before Sync:** Editing without save is pointless, but saves without editing is impossible; editor must exist first
- **Sync before Polish:** Core workflow (auth → browse → edit → save) must ship before optimization and UX refinement
- **This order avoids pitfalls:** Token refresh in Phase 1 prevents Pitfall 1 from affecting Phases 2-4; conflict detection in Phase 4 prevents Pitfall 2; dot-folder browser in Phase 2 prevents Pitfall 3; resumable uploads in Phase 4 prevent Pitfall 4; foreground refresh in Phase 4-5 prevents Pitfall 5

### Research Flags

**Phases likely needing deeper research during planning:**
- **Phase 1 (Foundation):** Google Drive API OAuth2 and token refresh — current SDK behavior with Xcode 16 should be verified; PKCE flow implementation may have updated best practices
- **Phase 2 (Browse):** Google Drive API folder listing — confirm exact query parameters for dot-folder inclusion and pagination; test with shared Drives for recursion issues
- **Phase 4 (Sync):** Google Drive ETag format and resumable upload reliability — official API documentation should be reviewed; rate limits and quota behavior should be tested

**Phases with standard patterns (can skip deep research):**
- **Phase 3 (Edit):** iOS text editing is well-documented; UITextView and SwiftUI TextEditor are standard frameworks. Toolbar markdown insertion is straightforward string manipulation
- **Phase 5 (Polish):** Network status detection (Network.framework), offline UX patterns, and error messaging are iOS best practices with ample documentation

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| **Stack Choice** | HIGH | Swift/SwiftUI is iOS 2025-26 standard; Google Drive REST API v3 is official and well-documented; version constraints are clear |
| **Features** | MEDIUM | Project scope is explicit (v1 = raw text, no preview); table stakes are industry standard for markdown editors; Google Drive-specific features inferred from API capabilities — full validation deferred to early user feedback |
| **Architecture** | MEDIUM | MVVM + component separation is established iOS pattern; Google Drive integration pattern is sound but specifics (pagination, quota handling) should be verified during Phase 1; conflict resolution approach is proven in Google Docs/Office but not tested in this codebase yet |
| **Pitfalls** | MEDIUM | Derived from iOS platform patterns, Google Drive API documentation, and markdown editor implementation experience; not verified against current Xcode 16 SDK or latest Google Drive API — recommend testing Phase 1 to validate token refresh behavior |

**Overall confidence:** MEDIUM — Research is informed by current training data (Feb 2025) and established iOS patterns, but several technical decisions should be validated during Phase 1 implementation (OAuth token refresh, dot-folder API behavior, ETag availability). No show-stoppers identified; pitfalls are well-understood and have clear mitigation strategies.

### Gaps to Address

1. **OAuth Token Lifecycle (Phase 1):** Training knowledge of GIDSignIn framework and token refresh is current but implementation details with Xcode 16 should be verified. Mitigation: Build Phase 1 Foundation first, test token refresh manually (force expiration, simulate network errors).

2. **Google Drive API Query Syntax (Phase 2):** Dot-folder visibility via `trashed=false` parameter is inferred but should be confirmed with official API documentation. Mitigation: Create test Drive with `.planning` folder, validate it appears in app's folder listing during Phase 2.

3. **ETag Format & Availability (Phase 4):** ETag-based conflict detection is assumed to be available in files.update response. Mitigation: During Phase 4, verify ETag format in API response and confirm it changes when file is modified externally.

4. **File Size Limits (Phase 4-5):** Research assumes Google Drive API doesn't impose hard file size limits <5MB for markdown files, but large file handling (resumable uploads, timeouts) should be tested. Mitigation: Phase 4 should test upload of 10MB+ file with network slowdown.

5. **iOS 16 vs 17 Trade-offs (Phases 1-5):** Stack recommends iOS 17+ for SwiftData, but iOS 16 support may be required. This affects data persistence approach. Mitigation: Early decision needed; Core Data fallback is documented in STACK.md.

## Sources

### Primary (MEDIUM-HIGH confidence)
- **STACK.md research:** Google Drive REST API v3 documentation, Swift.org, Apple SwiftUI/FileProvider documentation, GoogleSignIn SDK GitHub (v7.0+)
- **FEATURES.md research:** Project requirements (PROJECT.md), iOS markdown editor market patterns (training data), Google Drive API capabilities
- **ARCHITECTURE.md research:** iOS app architecture patterns (MVVM + Coordinator), Google Drive REST API v3 integration, OAuth 2.0 PKCE flow (RFC 7636)
- **PITFALLS.md research:** iOS platform patterns, Google Drive API limitations, markdown editor implementation experience, conflict resolution patterns from Google Docs/Office 365

### Secondary (MEDIUM confidence)
- Apple Human Interface Guidelines: Document-Based Apps
- iOS Keychain usage: Apple Security Framework documentation
- Conflict resolution UX: Common practice across Google Docs, Microsoft Office, Dropbox Paper

### Tertiary (confidence noted with gaps)
- Xcode 16 specific features and frameworks — not verified in this research
- Google Drive API v3 current limits and rate quotas — training data current to Feb 2025
- iOS 17+ specific behavioral changes — requires current iOS developer documentation

---

*Research completed: 2026-03-25*
*Ready for requirements & roadmap: yes*
*Recommended next step: Proceed to roadmap creation using phase structure above; validate Phase 1 technical decisions (token refresh, dot-folder API) during early implementation*
