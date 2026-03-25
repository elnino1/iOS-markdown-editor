# Phase 1: Core - Context

**Gathered:** 2026-03-25
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver the minimal working loop: open a markdown file (via in-app file picker or "Open With" from another app), edit it as raw text, and save it back to the original location. No syntax coloring, no unsaved indicator, no light/dark mode — those are Phase 2. Just the functional core.

</domain>

<decisions>
## Implementation Decisions

### Architecture
- Use UIDocument + UIDocumentPickerViewController — no Google OAuth or Drive API needed
- The "Open With" / document sharing mechanism handles all file sources (Google Drive, iCloud, local, Dropbox, etc.)
- For Google Drive use case: user browses in Google Drive app (which shows all folders including dot folders), then uses "Open With" to send the file to this app

### Home Screen
- Empty state with app name + "Open a markdown file to get started" prompt + prominent "Open File" button
- No recent files list in Phase 1 (deferred to Phase 3)
- Standard iOS navigation bar showing filename + actions (Open/Save buttons); editor fills remaining space below

### File Picker
- UIDocumentPickerViewController filtered to .md and .markdown files only
- "Open With" from another app opens the file immediately into the editor (no confirmation step)

### Save Behavior
- Auto-save after a short pause in typing (no explicit Save button in Phase 1)
- If user opens a new file while changes haven't been auto-saved yet: alert "Save changes before opening new file?" with Save / Discard / Cancel options

### Claude's Discretion
- Exact auto-save delay (e.g. 1-2 seconds after last keystroke)
- UIDocument vs manual file coordination implementation details
- Nav bar button layout and iconography

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project requirements
- `.planning/REQUIREMENTS.md` — FILE-01, FILE-02, EDIT-01, EDIT-02 are the Phase 1 requirements
- `.planning/PROJECT.md` — Architecture decisions (UIDocument model, no Drive API)
- `.planning/ROADMAP.md` — Phase 1 success criteria

### Research
- `.planning/research/STACK.md` — SwiftUI + UITextView wrapping guidance, iOS version targets
- `.planning/research/PITFALLS.md` — File coordination pitfalls, large file handling

No external ADRs or specs — requirements fully captured in decisions above.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- None — greenfield project, no existing code

### Established Patterns
- None yet — this phase establishes the foundation patterns

### Integration Points
- Phase 1 creates the app shell that Phase 2 (editor experience) builds on
- UIDocument model chosen here constrains how Phase 4 save-back works (already aligned)

</code_context>

<specifics>
## Specific Ideas

- The "Open With" flow is the primary use case for Google Drive files — user must browse in Google Drive app first, tap the file, then "Open With" this editor. The dot-folder problem is solved because the Google Drive app itself shows everything.
- In-app file picker is secondary / for local or iCloud files.

</specifics>

<deferred>
## Deferred Ideas

- Recent files list — Phase 3
- Sign-in screen / auth — no longer needed (removed in architectural pivot)
- Auth failure UX — no longer needed (no auth)
- Sign-out flow — no longer needed (no auth)
- Formatting toolbar — v2
- Markdown preview — v2

</deferred>

---

*Phase: 01-foundation*
*Context gathered: 2026-03-25*
