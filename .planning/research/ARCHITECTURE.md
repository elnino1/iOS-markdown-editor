# Architecture Patterns: iOS Markdown Editor with Google Drive

**Domain:** iOS document editing app with cloud storage integration
**Researched:** 2026-03-25
**Confidence:** MEDIUM (training-based; official Google Drive API docs would validate details)

## Recommended Architecture

### High-Level Data Flow

```
User Launch
    ↓
[Auth Manager] ← Authenticate with Google
    ↓
[Drive Browser] ← Fetch folder structure + metadata
    ↓ (User selects file)
[File Manager] ← Download file content
    ↓
[Editor] ← Display & edit content
    ↓ (User saves)
[Sync Manager] ← Upload changes back to Drive
    ↓
Success / Conflict Resolution
```

### Component Boundaries

| Component | Responsibility | Communicates With | Input | Output |
|-----------|---------------|-------------------|-------|--------|
| **AuthManager** | Google OAuth 2.0 token lifecycle, refresh, invalidation | All network components | None (triggers on app launch) | Valid access token, user info |
| **DriveManager** | Google Drive REST API calls — list files/folders, metadata queries | AuthManager | Folder ID, query filters | File/folder list, MIME types, modified timestamps |
| **DriveFileCache** | Local metadata cache to minimize Drive API quota consumption | DriveManager | Folder listings, file metadata | Cached file tree, timestamps for staleness checks |
| **FileSystemCoordinator** | Maps Google Drive file IDs ↔ local temp file paths; manages cached file content | AuthManager, DriveManager | File IDs | Local file paths, refresh triggers |
| **BrowseViewController (UI)** | Hierarchical folder browser — displays folder tree, allows drill-down to dot folders | DriveManager, DriveFileCache, FileSystemCoordinator | User taps on folders | Selected file ID, file name, MIME type |
| **TextEditorViewController (UI)** | Raw markdown text editing, toolbar formatting controls | FileSystemCoordinator, SyncManager | File content (string) | Edited text, save intent |
| **EditorState (ViewModel)** | Current file context — file ID, name, version, unsaved changes flag | BrowseViewController, TextEditorViewController | File selection, text changes | Dirty state, conflict warnings |
| **SyncManager** | Google Drive file uploads (PUT to Drive), conflict detection, retry logic | AuthManager, DriveManager, EditorState | File content (string), file ID, ETag | Success/failure, conflict resolution options |
| **ConflictResolver** | Prompts user on stale file edits; offers "overwrite," "discard," or "save as new" | TextEditorViewController, SyncManager | Server version, local version | User choice (enum) |

## Data Flow Details

### 1. Initial Auth Flow

```
App Launch
    → AuthManager checks for stored refresh token
      → If missing: Present Google Sign-In (OAuth 2.0 PKCE)
      → If present: Refresh access token silently
    → Store access token in Keychain (secured)
    → Proceed to BrowseViewController
```

**Key detail:** Use system browser (`ASWebAuthenticationSession`) for Google sign-in, not embedded web view, per Apple security best practices.

### 2. Drive Browse Flow

```
BrowseViewController loads
    → DriveManager queries Drive API: list children of folder
      Query: `trashed=false` (include all files, even those in trash from other apps)
      ⚠️ CRITICAL: No MIME type filter — allows dot folders and all file types
    → Results passed to DriveFileCache for storage
    → UI displays folder tree (non-recursive — load on demand)

User taps folder
    → DriveManager fetches children of new folder
    → Cache updates, UI refreshes

User taps file
    → FileSystemCoordinator triggered:
      - Check if file already cached locally
      - If not: DriveManager downloads content to temp directory
      - Return local file path to EditorState
    → Transition to TextEditorViewController
```

**Critical API detail:** Google Drive REST API `files.list()` returns all folders matching query, including those starting with `.` — unlike UIDocumentPickerViewController which filters these out. This is why direct API integration is necessary.

### 3. Edit & Save Flow

```
TextEditorViewController displays file content
    → User types (real-time local only, no network calls)
    → EditorState tracks `isDirty` flag

User taps "Save"
    → SyncManager prepares upload:
      - Fetches current file metadata (ETag/revision)
      - Compares with cached version from open time
      - Builds Drive API update request
    → Sends PUT request to Drive: `files/{fileId}` with updated content

Success case:
    → DriveFileCache invalidated for this file
    → EditorState.isDirty = false
    → Show confirmation toast

Conflict case (server version changed since open):
    → ConflictResolver presents options:
      1. "Overwrite Server" — upload local version
      2. "Discard Changes" — reload from server
      3. "Save As New" — create copy of edited version
    → User choice → execute selected action
```

### 4. Dot Folder Browsing (Differentiator)

```
User navigates Drive hierarchy:
    /
    ├── Documents
    ├── .claude         ← Standard apps hide this
    │   └── artifacts
    ├── .planning
    └── Projects

DriveManager queries with `trashed=false` (minimal filter)
    → API returns all folders regardless of name prefix
    → Cache stores all with folder names as-is
    → UI displays: ".claude", ".planning", etc.
    → User can drill in and edit files within
```

**Why this matters:** Standard iOS file pickers (UIDocumentPickerViewController) filter out dot folders. Direct Drive API use is required.

## Component Interaction Patterns

### Pattern 1: Network Request Resilience

**What:** All network calls (DriveManager, SyncManager) implement:
- Exponential backoff retry (quota exhaustion)
- Refresh token handling (expired auth)
- Graceful degradation (no network → use cache)

**When:** Any API call that could fail transitorily

**Example pseudocode:**
```swift
func listDriveFolder(folderId: String) async throws -> [DriveFile] {
    var retries = 0
    while retries < 3 {
        do {
            let token = try await authManager.getValidToken()
            let response = try await driveAPI.list(
                q: "'\(folderId)' in parents and trashed=false",
                spaces: "drive"
            )
            driveFileCache.update(folder: folderId, files: response.files)
            return response.files
        } catch AuthError.tokenExpired {
            try await authManager.refreshToken()
            retries += 1
        } catch APIError.quotaExceeded {
            try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(retries)) * 1_000_000_000))
            retries += 1
        } catch {
            // Fall back to cache if available
            return driveFileCache.getCachedFiles(folder: folderId) ?? []
        }
    }
    throw DriveError.failedAfterRetries
}
```

### Pattern 2: ViewModel as Coordinator

**What:** EditorState (ViewModel) acts as a mediator — it holds current file context and coordinates between BrowseViewController, TextEditorViewController, SyncManager, and ConflictResolver.

**When:** Any state needs to be shared across multiple views or persisted across navigation

**Why:** Keeps view controllers focused on UI logic; centralizes file/edit lifecycle.

### Pattern 3: Cache Invalidation

**What:** DriveFileCache stores:
- Folder listings with timestamps
- File metadata (name, size, modified time)
- Does NOT store file content (too large, goes to disk via FileSystemCoordinator)

**When:** Invalidate cache:
- After successful upload (entire folder tree is stale)
- After user navigates away from a folder (lazy reload)
- On explicit "refresh" user action

**Why:** Drive API has quota limits (1M requests/day); cache reduces calls.

### Pattern 4: File Content Locality

**What:** File content lives on disk (temp directory), not memory. Only paths/IDs in memory.

**When:** Always, even for small files (keeps memory predictable)

**Why:** A 1MB markdown file shouldn't bloat the app's RAM.

## Anti-Patterns to Avoid

### Anti-Pattern 1: Embedding WebView for Auth

**What:** Using `UIWebView` or embedded Chrome for Google sign-in
**Why bad:**
- Apple App Review rejects this (no embedded browsers for auth)
- Security risk (credentials visible in webview memory)
- Loses SSO benefits of system auth

**Instead:** Use `ASWebAuthenticationSession` (iOS 12+) or `GoogleSignInSwift` framework

### Anti-Pattern 2: Synchronous Network Calls

**What:** Blocking the main thread on Drive API requests
**Why bad:**
- UI freezes during list/upload
- Poor user experience
- Violates iOS best practices

**Instead:** All network work via `async/await` on background executors

### Anti-Pattern 3: Unbounded Cache Growth

**What:** Caching file listings indefinitely without cleanup
**Why bad:**
- Memory grows with Drive folder depth
- Stale data causes sync conflicts
- No way to "refresh" to get truth

**Instead:** Implement cache TTL (5–15 min) + manual invalidation post-upload

### Anti-Pattern 4: Storing Access Tokens in UserDefaults

**What:** Putting OAuth tokens in plaintext UserDefaults
**Why bad:**
- Anyone with physical access reads tokens
- Backed up to iCloud unencrypted
- Violates OAuth 2.0 security practices

**Instead:** Use Keychain (encrypted at rest, per-user)

### Anti-Pattern 5: Single Monolithic View Controller

**What:** One massive ViewController handling browse + edit + save
**Why bad:**
- Hard to test
- High risk (logic coupled to UI)
- Impossible to reuse components

**Instead:** Separate concerns — BrowseViewController, TextEditorViewController, ViewModels

## Scalability Considerations

| Concern | At 100 files | At 10K files | At 100K files |
|---------|--------------|--------------|---------------|
| Folder listing latency | <500ms (1–2 API calls) | 1–2s (pagination) | 5–10s (deep pagination, quota throttling) |
| Cache memory | ~1MB (metadata) | ~10MB (metadata + some file content) | ~100MB+ (need pruning) |
| Sync conflict risk | Low (single user) | Low (single user, slower ops) | Medium (slow uploads = more stale reads) |
| Approach | Load-on-demand tree | Pagination + search | Pagination + folder-level caching, search |

**Practical limits for v1:**
- Support up to ~10K files without major re-architecting
- Beyond that: implement Drive search (not folder hierarchy browse)
- Pagination will be needed in BrowseViewController when a folder has >100 children

## Build Order & Dependencies

**Phase 1: Foundation (Auth + Drive connection)**
1. AuthManager (token lifecycle, OAuth 2.0 setup)
2. DriveManager (files.list, files.get, files.update APIs)
3. Test auth flow end-to-end (sign in, refresh, invalid token recovery)

**Phase 2: Browse (Display Drive hierarchy)**
1. DriveFileCache (simple in-memory metadata store)
2. BrowseViewController (folder tree UI, drill-down)
3. FileSystemCoordinator (map Drive IDs → local paths)
4. End-to-end: Browse to a file, see it listed

**Phase 3: Edit (Open + modify)**
1. TextEditorViewController (raw text view, keyboard handling)
2. EditorState (track current file + unsaved changes)
3. Toolbar (bold, italic, headers, bullets — local formatting only)
4. End-to-end: Open a file, edit it, see "unsaved changes" indicator

**Phase 4: Sync (Save back to Drive)**
1. SyncManager (files.update API, ETag handling)
2. ConflictResolver (present user choice on stale file)
3. Retry logic (exponential backoff for quota exhaustion)
4. End-to-end: Edit, save, see file updated in Drive

**Phase 5: Polish (Edge cases)**
1. Network error handling (offline mode with fallback)
2. File size limits (warn if >5MB)
3. Character encoding (UTF-8 default, detect others)
4. Cache invalidation on foreground (refresh button)

## Google Drive API Authentication Flow

### Initial Setup

```
User launches app
    → Check Keychain for refresh token
    → If missing:
        → Prompt "Sign in with Google"
        → Redirect to Google OAuth consent screen (system browser)
        → Google returns authorization code
        → Exchange code for access token + refresh token
        → Store refresh token in Keychain
    → If present:
        → Exchange refresh token for new access token (silent)
    → Proceed to main UI with valid access token
```

### Refresh Token Lifecycle

```
AuthManager.getValidToken() async throws -> String {
    if accessToken.isExpired() {
        do {
            (accessToken, refreshToken) = try await exchangeRefreshToken()
            Keychain.store(refreshToken)
        } catch AuthError.refreshFailed {
            // Refresh token revoked or expired
            Keychain.delete(refreshToken)
            throw AuthError.requiresReauth
        }
    }
    return accessToken
}
```

### OAuth 2.0 Scopes Required

```
https://www.googleapis.com/auth/drive.file
```

(Not `drive` full scope — only access files created by this app or explicitly opened by user)

### Key Implementation Detail: PKCE for Mobile

Use PKCE (Proof Key for Code Exchange) flow:
- Generate `code_challenge` from `code_verifier`
- Include in authorization request
- Include `code_verifier` in token exchange request
- Prevents authorization code interception on device

## Conflict Resolution Strategy

When SyncManager detects a stale file (ETag mismatch):

```
File opened at: 2026-03-25 10:00:00 (ETag: "abc123")
User edits for 15 minutes
User taps "Save" at 10:15:00

SyncManager fetches current file:
    → ETag: "def456" (file changed on server)
    → ConflictResolver.present() → User sees dialog:

        "This file was changed on Google Drive.
        Your changes will be lost if you don't choose carefully.

        [Overwrite Server] [Discard Changes] [Save as New]"

        Overwrite Server → SyncManager uploads with force=true
        Discard Changes → Reload from Drive, abandon local edits
        Save as New → Create "filename-2.md" with local version
```

**Why this UX:** Single user editing their own Drive. Conflicts are rare but need human choice.

## File Versioning Strategy

**For v1:** No explicit versioning — leverage Google Drive's built-in revision system:
- Drive API keeps file revision history automatically
- User can view/restore versions in Google Drive web interface
- This app doesn't expose version UI (future enhancement)

**Rationale:** Simpler to build; Google handles it; common user mental model

## Sources

- Apple Human Interface Guidelines: Document-Based Apps (MEDIUM confidence)
- iOS app architecture patterns: MVVM + Coordinator (MEDIUM confidence)
- Google Drive REST API v3 documentation: files.list, files.get, files.update endpoints (MEDIUM confidence — would need official docs verification)
- OAuth 2.0 PKCE flow for mobile apps: RFC 7636 (MEDIUM confidence)
- iOS Keychain usage for token storage: Apple Security Framework documentation (MEDIUM confidence)
- Conflict resolution patterns in document editing: Common practice across Google Docs, Microsoft Office, Dropbox Paper (MEDIUM confidence)

## Confidence Assessment

| Area | Level | Reason |
|------|-------|--------|
| Component structure | MEDIUM | Based on iOS architecture patterns; actual codebase may refine further |
| Google Drive API integration | MEDIUM | Training knowledge of v3 API; would validate with official Google documentation |
| Auth flow (OAuth 2.0 + PKCE) | MEDIUM | Standard mobile auth best practice; could vary with specific implementation details |
| Conflict resolution | MEDIUM | Pattern used in Google Docs, Office 365, Dropbox; suitable for single-user scenario |
| Dot folder support via API | MEDIUM-HIGH | Google Drive API does NOT filter dot folders; UIDocumentPickerViewController does — differentiator confirmed |

## Gaps to Address in Phase-Specific Research

- **Phase 2 (Browse):** Need to verify exact Drive API query parameters for listing (does `trashed=false` include dot folders? need official confirmation)
- **Phase 4 (Sync):** ETag vs. appProperties for version tracking — which approach is more reliable for detecting conflicts?
- **General:** File size limits — does Google Drive API reject files >100MB? Need official limits documentation
- **General:** Rate limits and quota — what's the practical request ceiling for a personal use app? (1M requests/day is quota, but what's sustainable?)

---

*Last updated: 2026-03-25*
