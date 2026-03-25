# Domain Pitfalls: iOS Google Drive Markdown Editor

**Domain:** iOS app with Google Drive integration, markdown editing, dot-folder browsing
**Researched:** 2026-03-25
**Confidence:** MEDIUM (training data + established iOS patterns, current APIs not verified via Context7)

---

## Critical Pitfalls

These mistakes cause rewrites, data loss, or core feature failure.

### Pitfall 1: OAuth Token Expiration & Refresh Loop

**What goes wrong:**
OAuth tokens expire (default: 1 hour for Google Drive API). Apps that don't properly handle refresh tokens end up:
- Users suddenly unable to access Drive mid-editing session
- Save operations silently fail or throw cryptic errors
- Users forced to re-authenticate frequently (killing app appeal)
- Token refresh attempts that loop infinitely, blocking UI

**Why it happens:**
- Storing only access tokens, discarding refresh tokens
- Not catching specific token expiration errors (401 Unauthorized)
- Attempting to refresh synchronously on main thread
- Race conditions when multiple requests fire simultaneously with expired token

**Consequences:**
- User edits lost (no rollback for local-only drafts if auto-save was planned for v2)
- Poor UX (frequent forced re-authentication)
- If handled badly, app crashes with cryptic "unauthorized" errors
- Data loss risk if save operation fails silently

**Prevention:**
1. Always store and manage refresh tokens securely in Keychain
2. Catch 401 Unauthorized responses, automatically refresh token, retry request once
3. Implement exponential backoff for token refresh failures
4. Use GIDSignIn framework's built-in token management (handles refresh automatically)
5. Log token expiration events for debugging
6. Test token refresh scenario: manually expire tokens, simulate network conditions

**Detection:**
- User reports "I was editing and suddenly couldn't save"
- Logs show 401 errors followed by app crash or freeze
- Save operations sometimes succeed, sometimes silently fail
- Users need to log in again within editing session

**Phase:** Foundation (Phase 1) — Must be correct before any Drive integration
**Specific focus:** Use Google's GIDSignIn framework which handles token lifecycle automatically; avoid manual HTTP client approaches

---

### Pitfall 2: File Conflict on Save (Concurrent Edits)

**What goes wrong:**
When file is edited in Drive web or another app simultaneously:
- App saves version A, Drive had version B, version A overwrites B (data loss)
- App loads file at timestamp X, user edits, saves — but file was updated at X+5min externally
- No conflict detection, no merge, no warning
- User loses external edits without knowing

**Why it happens:**
- No ETag/revision checking before save
- Naive implementation: read file, edit, write file (no locking)
- Not checking file modification time between load and save
- Google Drive allows concurrent edits from multiple sources intentionally

**Consequences:**
- User A edits file, saves; User B's simultaneous edits are lost
- Data loss with no recovery possible
- User trust completely broken ("I lost 2 hours of work")
- For shared Drive folders (not v1 scope, but worth noting), this is catastrophic

**Prevention:**
1. Implement ETag-based conflict detection: store ETag when file loaded, check against current ETag before save
2. If ETags don't match, alert user: "File has been changed externally. Overwrite? | Discard my changes | Compare"
3. For v1 (single-user assumed), simplest: just warn "File changed, save anyway?" and let user decide
4. Implement last-write-wins with user notification (not silent overwrite)
5. Log all save operations with timestamps and file metadata
6. Test: open file in web Drive, edit and save, then save from app

**Detection:**
- User reports "my changes disappeared" or "another edit overwrote mine"
- File history in Drive shows unexpected overwrites
- Multiple versions of same file appearing in Drive

**Phase:** Editing Foundation (Phase 2) — Must be in place before save feature ships
**Specific focus:** Google Drive API provides file revision tracking; use it before every save

---

### Pitfall 3: Dot Folder Access Denied (Permissions/API Scope)

**What goes wrong:**
App attempts to browse dot folders (`.claude`, `.planning`, etc.) but:
- Google Drive API doesn't return them (hidden by default query filters)
- UIDocumentPickerViewController won't let user select them
- App shows empty folder even though `.planning/research/` exists
- User assumption: "The app is broken, these folders don't exist in my Drive"

**Why it happens:**
- Standard file listing queries filter out dot files by default (Unix convention)
- UIDocumentPickerViewController (Files app picker) has no way to show hidden files
- Google Drive doesn't distinguish "hidden files" — dot convention is just a naming pattern
- App scope may not include correct Drive permissions for all files

**Consequences:**
- Core value proposition ("access dot folders") completely broken
- App appears to show only partial Drive structure
- Users can't access their `.planning/`, `.claude/` files — defeating the entire purpose
- Looks like a fundamental limitation, not a fixable bug

**Prevention:**
1. When querying Google Drive API, explicitly request files with names starting with `.`:
   - Don't apply default "hide dotfiles" filters
   - Query: `(name contains '.' or name = 'folder')` to catch all names
2. For direct file access: once user has authenticated, app has access to all their Drive files by permission, dot-prefixed or not
3. Document that UIDocumentPickerViewController cannot browse Drive fully — must use custom Drive browser for dot folder access
4. Implement custom file browser UI using Google Drive API directly (list files, navigate folders) instead of relying on system picker
5. Test explicitly: create `.planning` folder in test Drive, verify it appears in app's folder list

**Detection:**
- User sees partial folder structure in app vs. complete structure in Drive web
- "I can see `.planning` in Drive web but not in your app"
- Folder appears empty when it contains dot-prefixed files

**Phase:** Foundation (Phase 1) — Must work for core feature to exist
**Specific focus:** Custom folder browser using Drive API is mandatory, not optional

---

### Pitfall 4: Large File / Network Timeout During Save

**What goes wrong:**
Editing larger markdown files (100KB+) or on slow networks:
- Save operation times out or fails mid-stream
- No partial save, no resume capability
- User loses all unsaved edits
- No indication to user that save failed (silent failure worst case)
- Retrying save can create duplicate versions

**Why it happens:**
- Using synchronous file upload with default network timeout
- No chunked/resumable upload for larger files
- No checksum verification (might save corrupted partial file)
- Network conditions not handled: WiFi dropout, cellular switch

**Consequences:**
- User edits 50KB markdown file, hits save, network drops, entire file lost
- Silent failures worst — app says "Saved" but upload actually failed
- Users forced to keep local copies to avoid loss
- If conflicts arise from retry, more data loss

**Prevention:**
1. Implement resumable file uploads (Google Drive API supports this)
2. Set reasonable timeout (30+ seconds) and retry logic (exponential backoff)
3. Show upload progress indicator and allow user to cancel
4. For v1, acceptable approach: show "Saving..." spinner, only allow one save at a time
5. Verify uploaded file size matches local file size
6. Use content hashing if possible to verify integrity
7. Test: simulate network slow-down, file drops, WiFi to cellular switch during save

**Detection:**
- User reports "sometimes saves just disappear"
- Multiple versions of file in Drive (retry created dupes)
- File size in Drive doesn't match what user expects
- On poor network, saves consistently fail or timeout

**Phase:** Editing (Phase 2) — Critical before release
**Specific focus:** Use Google Drive API's resumable upload with proper error handling

---

### Pitfall 5: State Management After App Backgrounding

**What goes wrong:**
User edits file, app backgrounded (user switches apps), returns later:
- OAuth token refreshed but session inconsistent
- File was changed externally while app was backgrounded, app unaware
- User resumes editing stale content
- Save overwrites external changes with stale local data

**Why it happens:**
- No state refresh when app returns from background
- URLSession delegates not properly managed across app lifecycle
- Assumption that in-memory state is still valid after backgrounding
- No mechanism to check if file was modified while backgrounded

**Consequences:**
- Silent data loss if external change and local change both happen
- User doesn't know file was changed externally
- Trust broken: "Why did my Drive file change?"

**Prevention:**
1. Implement `sceneWillEnterForeground` handler to refresh file metadata
2. When returning from background, check current file's metadata (modification time, ETag)
3. If file changed externally while backgrounded, alert user before allowing further edits
4. If stale, offer: "File changed externally. Reload? | Discard external changes | Cancel"
5. Keep background session for save operations (allow save even if app backgrounded)
6. Test: edit file, background app for 5min, edit file in Drive web, return to app

**Detection:**
- User backgrounded app, edited in Drive, returned to app to continue editing
- External edits silently lost when user saved
- "Why is my Drive different from what I was editing?"

**Phase:** Editing (Phase 2)
**Specific focus:** App lifecycle and background state management critical for reliability

---

### Pitfall 6: Insufficient OAuth Scope or Permission Errors

**What goes wrong:**
App requests minimal OAuth scope to avoid prompting (good intent):
- OAuth only requests `drive.file` (modify specific files)
- User browses to folder they don't have write access to (shared read-only)
- App shows "Permission denied" when trying to save
- User expects to be able to edit any file they can see in Drive web
- Discrepancy confuses users: "I can edit this in Drive web, why not in your app?"

**Why it happens:**
- Requesting minimal scope to seem less invasive
- Not testing with shared/read-only files
- Drive API permissions model not fully understood
- User's expectation: "If I can see it and edit it in Drive, I can in this app"

**Consequences:**
- User encounters file they can't edit (hidden permission issue)
- Workflow blocked for shared Drives or read-only shared folders
- Apparent app limitation, not permissions limitation

**Prevention:**
1. Request `drive` scope (full Drive access) for files user owns; this is standard for editors
2. Document: app works with files user has write permission for
3. When save fails with permission error, show clear message: "You don't have permission to edit this file"
4. Before save, check file's `canEdit` or ownership property
5. Test with shared read-only file, shared with write access, and files user doesn't have permission for
6. If permission denied, offer alternative: "Save as copy to your Drive"

**Detection:**
- User tries to save file in shared folder: "Permission denied"
- App works for personal Drive files but not shared files user expects to edit
- Discrepancy between Drive web permissions and app permissions

**Phase:** Foundation (Phase 1) — Clarify scope and permissions early
**Specific focus:** Use `drive` scope and clearly communicate permission requirements

---

## Moderate Pitfalls

### Pitfall 7: Text Encoding Issues (UTF-8 Assumptions)

**What goes wrong:**
Markdown files with special characters, emoji, or non-ASCII text:
- App reads file as UTF-8, assumes it's valid
- File is actually different encoding (ISO-8859-1, UTF-16, etc.)
- Save corrupts characters: café becomes cafÃ©
- Bidirectional text (Arabic, Hebrew) renders incorrectly or damages file

**Why it happens:**
- Assuming UTF-8 without checking file encoding
- iOS text APIs default to UTF-8, no fallback
- Not preserving original encoding when saving

**Prevention:**
1. When loading file, attempt UTF-8 first; if fails, try common alternatives
2. Detect BOM (Byte Order Mark) to identify UTF-16/32
3. Always save with UTF-8 (most compatible)
4. Test with files containing emoji, accented chars, RTL text
5. Log encoding detection for debugging

**Detection:**
- User reports "Special characters got corrupted"
- Emoji or accented text looks wrong in app but correct in Drive web

**Phase:** Editing (Phase 2) — Before handling real user files
**Specific focus:** Always assume UTF-8, but detect and handle other encodings gracefully

---

### Pitfall 8: Infinite Folder Recursion (Symlinks or Drive Quirks)

**What goes wrong:**
App browses Drive folders recursively:
- Some shared Drives have folder structures that appear circular
- Google Drive shortcuts can create apparent loops
- App navigates folder, child appears to contain parent (or self)
- Browser crashes, hangs, or gets into infinite loop
- Out of memory from recursive depth

**Why it happens:**
- Not tracking visited folder IDs during recursive browse
- Not handling Drive shortcuts (which can point anywhere)
- Folder ID can appear in its own children in certain permission scenarios
- Naive recursive folder listing without depth limit

**Prevention:**
1. Track visited folder IDs to detect cycles
2. Set maximum folder depth limit (e.g., 50 levels)
3. Handle Drive shortcuts: don't follow them, or follow once with visited set
4. Test: create shared Drive folder structure, use shortcuts, verify no loops
5. Add assertion: if folder ID appears in path twice, something's wrong

**Detection:**
- App hangs when browsing specific folder structure
- Memory usage climbs, crashes with memory warning
- "Folder appears to contain itself" in folder list

**Phase:** Foundation (Phase 1) — Fix before release
**Specific focus:** Visited set pattern during folder enumeration

---

### Pitfall 9: Markdown Formatting Corruption on Save

**What goes wrong:**
User applies toolbar formatting (bold, italic, headers):
- Toolbar inserts markdown syntax incorrectly
- Selection handling broken: formatting applied to wrong range
- Special characters in formatting conflict with file content
- User formats text, saves, opens file and finds malformed markdown

**Why it happens:**
- Not properly tracking text selection state
- Formatting insertion logic not accounting for cursor position changes
- String manipulation off-by-one errors
- Not escaping special characters in user content

**Prevention:**
1. When inserting markdown syntax (e.g., `**bold**`), explicitly test:
   - Select text, apply bold, verify `**selected text**` appears
   - Undo works correctly (using UITextView undo manager)
   - Cursor positioned correctly after formatting
2. Use proper text view APIs (not string manipulation):
   - `UITextView.replace(_:with:)` to modify text safely
   - Track selection before/after formatting
3. Test toolbar on text containing:
   - Special characters: `#`, `*`, `[`, `]`, `(`, `)`
   - Line breaks within selection
   - Emoji
4. Verify saved markdown parses correctly (lint with markdown parser)

**Detection:**
- User applies formatting, saves, opens in Drive web: markdown looks broken
- "Bold didn't apply" or "Characters got duplicated"
- Markdown linter shows syntax errors in files user formatted in app

**Phase:** Editing (Phase 2) — Before toolbar release
**Specific focus:** Thorough selection/cursor management in text editing

---

### Pitfall 10: No Offline Support, Confusing UX When Offline

**What goes wrong:**
User editing file, loses network:
- Open file works (cached?), but save silently fails
- User doesn't realize: assumes changes saved to Drive
- Closes app, opens later on different device: changes gone
- Expectation: "I was connected, how did this happen?"

**Why it happens:**
- No detection of network status
- Caching behavior opaque to user
- No offline indicator in UI
- Save API returns success but isn't actually synced to Drive

**Prevention:**
1. Detect network status using Network.framework or Reachability
2. Show network status indicator in UI (always visible, simple)
3. On save attempt when offline, fail immediately with clear message:
   - "No internet connection. Changes saved locally. Will sync when online." (if v1 supports local cache)
   - Or: "No internet connection. Can't save to Drive right now. Check connection."
4. For v1 (no offline support): disable save button when offline
5. Test: disconnect WiFi, attempt save, verify error message
6. Document: "Requires internet to save"

**Detection:**
- User reports changes lost after reconnecting
- Users expect offline editing capability
- Confusion about whether file actually saved

**Phase:** Editing (Phase 2) — Network state handling
**Specific focus:** Explicit offline indicator and clear error messages

---

## Minor Pitfalls

### Pitfall 11: Poor Error Messages

Users encounter: "Error (403)", "Request failed", "Unknown error"
- App logs have useful info, but users see nothing
- Users contact developer with "It doesn't work" with no context

**Prevention:**
1. Specific error messages:
   - Instead of "Error saving": "Permission denied: you don't have write access to this file"
   - Instead of "Network error": "No internet connection. Check WiFi and try again."
2. Log full error details locally for debugging
3. Offer user action: "Retry", "Cancel", "Open settings"

**Phase:** Editing (Phase 2) — Polish

---

### Pitfall 12: Toolbar UX Confusion (Markdown Syntax Visibility)

User applies bold formatting but doesn't see `**text**` markdown in editor:
- Some markdown editors hide syntax, show bold rendering
- This app (v1) shows raw markdown
- User applies formatting, confused why they see `**text**` instead of bold text

**Prevention:**
1. Make clear in UI: "This is a raw markdown editor. Formatting appears as markdown syntax."
2. Show example in onboarding: "Select text, tap Bold. You'll see **bold syntax**."
3. In toolbar button labels: "Bold (adds ** markers)" not just "B"

**Phase:** Editing (Phase 2) — UX clarity

---

### Pitfall 13: File Name Encoding Issues on Save

Google Drive allows file names with special characters that iOS file system doesn't:
- User edits file named `my-file-é.md` in Drive
- Save back may corrupt filename or fail silently
- File renames unexpectedly in Drive

**Prevention:**
1. When saving, preserve original filename exactly (don't sanitize)
2. Google Drive API handles special chars fine; just pass through
3. Test with: accented chars, emoji, spaces, special chars in filename

**Phase:** Editing (Phase 2)

---

## Phase-Specific Warnings

| Phase | Topic | Likely Pitfall | Mitigation |
|-------|-------|----------------|------------|
| Phase 1: Foundation | OAuth Integration | Token expiration, insufficient scope | Use GIDSignIn framework; implement refresh logic; request `drive` scope |
| Phase 1 | Drive Browsing | Dot folders not visible | Custom Drive browser using API; don't use UIDocumentPickerViewController alone |
| Phase 1 | File Permissions | "Permission denied" confusion | Check `canEdit` before operations; clear error messaging |
| Phase 2: Editing | Save Implementation | Concurrent edits cause overwrite | Implement ETag-based conflict detection |
| Phase 2 | Save Reliability | Network timeout, large files | Resumable uploads; timeout handling; progress indication |
| Phase 2 | App Backgrounding | Stale state, external changes missed | Refresh metadata on foreground; check for external modifications |
| Phase 2 | Text Encoding | Non-UTF-8 files corrupted | Support encoding detection; always save UTF-8 |
| Phase 2 | Toolbar | Markdown corruption on formatting | Careful selection handling; test with special characters |
| Phase 2 | UX | User offline, doesn't know | Network indicator; disable save offline; clear messaging |
| v2+ | Shared Drives | File conflicts; permission cascades | Conflict resolution UI; permission model documentation |
| v2+ | Large Files | Memory pressure; upload timeout | Implement chunked upload; handle memory warnings |
| v2+ | Preview Mode | Preview-edit state mismatch | Ensure both use same markdown parser; test sync |

---

## Sources & Confidence Notes

**Confidence: MEDIUM**

These pitfalls are derived from:
1. Established iOS platform patterns (UITextView, URLSession, app lifecycle)
2. Well-documented Google Drive API limitations (token refresh, ETag, permissions, shortcuts)
3. Common markdown editor implementation issues (text selection, encoding, formatting)
4. Industry standard mistakes (concurrent edit handling, offline UX, error messaging)

**Not verified via:**
- Current Google Drive iOS SDK documentation (Context7 unavailable)
- Recent API changes (knowledge cutoff: February 2025)
- Specific iOS 17+ behavioral changes

**Recommended validations during Phase 1 & 2:**
- Verify token refresh behavior with current GIDSignIn SDK
- Test dot-folder listing with current Google Drive API
- Confirm ETag availability and format
- Test resumable upload implementation
- Verify Network.framework availability target iOS version

---
