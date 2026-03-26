# Phase 3: Polish - Context

**Gathered:** 2026-03-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Handle edge cases, improve reliability, and smooth rough edges. This phase does NOT add new user-facing features — it makes the existing open/edit/save loop resilient: surfaces errors that are currently silent, guards against large or non-UTF-8 files, and adds a recently-opened files list to reduce navigation friction.

</domain>

<decisions>
## Implementation Decisions

### Error Messages
- Use alert dialogs (`.alert` modifier) — consistent with the existing unsaved-changes alert pattern in EditorView
- Cover all three failure scenarios: (1) file open failed (UIDocument.open returns false), (2) file picker error (fileImporter `.failure`), (3) save failed
- Show error-type-specific messages — map system error codes to user-friendly phrases:
  - Permission denied → "You don't have permission to open this file."
  - File not found → "The file could not be found. It may have been moved or deleted."
  - Unreadable / corrupt → "Couldn't read this file. It may be damaged or in an unsupported format."
  - Save failed → "Changes couldn't be saved. Check that the file is still accessible."
  - Fallback (unknown) → "Something went wrong. Please try again."
- For open errors (picker error + UIDocument open failure): include a "Try Again" button that reopens the file picker
- For save errors: dismiss-only (no retry button — user can continue editing)

### Claude's Discretion
- Large file handling: size threshold choice, whether to warn-only or also disable highlighting above threshold, exact UI (alert vs inline banner)
- Encoding notification: whether to show any user-visible indicator when latin1 fallback is used, and how to handle the encoding-change-on-save scenario
- Recent files list: storage mechanism (UserDefaults vs SwiftData), UI layout (list rows in HomeView is the natural fit), item count limit, swipe-to-remove behavior

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

No external specs or ADRs — requirements fully captured in decisions above and project files below.

### Project requirements
- `.planning/REQUIREMENTS.md` — Phase 3 has no formally mapped v1 requirements; success criteria live in ROADMAP.md
- `.planning/ROADMAP.md` — Phase 3 success criteria (4 observable behaviors to achieve)
- `.planning/PROJECT.md` — Core constraints (free app, iOS only, no backend, simple editor)

### Existing implementation (read before touching these files)
- `MarkdownEditor/AppState.swift` — `_openDirectly` has the `if success == false` silent drop; `open()` and `closeCurrentDocument()` are the entry points
- `MarkdownEditor/HomeView.swift` — fileImporter `.failure` path is currently a console print; recent files list goes here
- `MarkdownEditor/EditorView.swift` — save path via `doc.save(to:for:)` in `saveImmediately`; existing `.alert` pattern to reuse
- `MarkdownEditor/MarkdownDocument.swift` — `load(fromContents:)` already has UTF-8 + latin1 fallback; `contents(forType:)` always writes UTF-8

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `.alert` modifier with buttons: already used in EditorView for unsaved-changes dialog — reuse this exact pattern for error alerts
- `AppState.open(url:)`: existing entry point for file opens; error handling should flow through here or `_openDirectly`
- `MarkdownDocument.load(fromContents:)`: already throws `CocoaError(.fileReadCorruptFile)` on bad data — error type is available

### Established Patterns
- Error presentation: SwiftUI `.alert` modifier on the relevant view (HomeView for open errors, EditorView for save errors)
- Main actor dispatch: all AppState mutations use `Task { @MainActor }` — error state @Published vars follow the same pattern
- UIDocument lifecycle: `doc.open { success in ... }` and `doc.save(to:for:) { success in ... }` are the callback sites

### Integration Points
- Open error: `AppState._openDirectly` → `if success == false` branch → publish an error to HomeView
- Picker error: `HomeView` fileImporter `.failure(let error)` → parse the error → show alert
- Save error: `EditorView.saveImmediately(completion:)` → the closure receives `success: Bool` → show alert if false
- Recent files: `HomeView` body — add a List section above or below the empty state; `AppState` or a dedicated `RecentFilesStore` tracks URLs

</code_context>

<specifics>
## Specific Ideas

- No specific design references provided — standard iOS alert dialogs match the existing app style
- "Try Again" on open errors should re-trigger the file picker, same as tapping "Open File" from scratch

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 03-polish*
*Context gathered: 2026-03-26*
