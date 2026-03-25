# Feature Landscape

**Domain:** iOS markdown editor with cloud storage (Google Drive)
**Researched:** 2026-03-25
**Scope:** v1 = raw text editor only; v2 = add preview
**Confidence:** MEDIUM (project requirements clear; full ecosystem validation deferred to early user feedback)

## Table Stakes

Features users expect from a markdown editor. Missing any = product feels incomplete and loses users immediately.

| Feature | Why Expected | Complexity | v1/v2 | Notes |
|---------|--------------|------------|-------|-------|
| **Browse cloud storage hierarchy** | Users need to navigate files they already have in Drive; essential for the core value prop (access dot folders) | Medium | v1 | Must show full tree including `.` prefix folders; this is the differentiator vs. competitors that hide dot folders |
| **Open markdown files** | Can't edit files you can't open | Low | v1 | Single-file open workflow; assume `.md` extension or plain text |
| **Raw text editing** | Core function: edit markdown as plain text | Low | v1 | WYSIWYG deferred to v2; users expect simple text entry with cursor control |
| **Save to cloud** | Changes must persist; users expect edits to go back to Drive | Medium | v1 | OAuth2 integration with Google Drive API; atomic saves to prevent data loss |
| **Basic text formatting toolbar** | Users expect quick formatting without typing markdown syntax | Medium | v1 | Bold, italic, headers (h1-h3), bullet lists, numbered lists minimum; inline code optional |
| **File metadata display** | Users need to know file location, size, last modified | Low | v1 | Brief display in editor header or details pane |

## Differentiators

Features that set the product apart. Not expected universally, but valued by power users and competitive advantages.

| Feature | Value Proposition | Complexity | v1/v2 | Notes |
|---------|-------------------|------------|-------|-------|
| **Dot folder browsing** | OTHER APPS HIDE THESE. Users with `.claude/`, `.planning/`, `.git` config files in Drive can use this app; can't use Markdown Pro or similar | High | v1 | This is THE differentiator; core reason product exists. Requires explicit handling in Google Drive API (no filters) and UI design that doesn't suppress hidden files |
| **Keyboard shortcuts** | Fast power users want Command+B for bold, Command+Z for undo | Medium | v1 | iOS keyboard shortcuts framework; not essential but increases perceived polish |
| **Search within file** | Find/Replace for markdown syntax errors or large documents | Low-Medium | v1 | Command+F pattern; low complexity, high utility |
| **Multiple file tabs** | Users often flip between related markdown files (e.g. editing notes while referencing template) | Medium | v2+ | Deferred; v1 uses single-file workflow |
| **Sync status indicator** | Users need confidence that changes are persisted to Drive, not lost | Low | v1 | Visual indicator (checkmark, spinner) showing "saved" / "syncing" / "failed" state |
| **Offline editing with sync** | Edit markdown locally, sync to Drive when online | High | v2+ | Requires local caching, conflict detection, diff tracking; deferred beyond MVP |
| **Markdown preview (live side-by-side)** | See rendered output while editing | Medium | v2 | Deferred per PROJECT.md; v1 is raw text only |
| **Syntax highlighting** | Markdown syntax colored for readability | Low-Medium | v1-optional | Nice-to-have; improves UX but not critical for MVP |

## Anti-Features

Things to deliberately NOT build in v1. Scope creep kills projects.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| **Note-taking / organizational features** | This is an editor, not a notes app. Adding notebooks, tags, search across all files, etc. turns it into a different product | Focus on editing experience only. If users want a notes app, recommend Bear/Notion/Obsidian |
| **Local file storage / sync** | "Download to device" for offline access requires complex sync logic, conflict resolution, local caching | Drive-only for v1. If offline editing is critical, that's v2 scope and needs architecture redesign |
| **WYSIWYG editing** | Requires a rich text editor component, significant complexity, diverges from markdown purity | Explicitly defer to v2; keep v1 as raw text with formatting toolbar (buttons, not WYSIWYG) |
| **Formatting that's not markdown** | Bold text stored as rich text (not `**bold**`), markdown extensions that aren't portable | Ensure all toolbar actions produce valid, standard markdown syntax |
| **Real-time collaboration** | Multiple users editing same file simultaneously; requires live sync, conflict detection, operational transforms | Out of scope; single-user editing only |
| **AI features (summarize, suggest, etc.)** | Tempting but requires backend, API keys, costs, privacy concerns | Not for v1; stay focused on editing |
| **Custom syntax themes** | Allow users to customize editor colors | Defer; use system light/dark mode only for v1 |
| **Export to PDF, HTML, etc.** | Adds scope without adding user value for markdown editing | Out of scope; users export from their notes app if needed |

## Feature Dependencies

Ordering constraints for MVP and v2:

```
v1 MVP (raw editor only):
┌─────────────────────────────────────┐
│ Google Drive OAuth2 login           │
└────────────────┬────────────────────┘
                 │
    ┌────────────┴────────────┐
    │                         │
    v                         v
┌──────────────────┐    ┌─────────────────────┐
│ Browse folders   │    │ Open markdown file  │
└────────────────┬─┘    └──────────┬──────────┘
                 │                 │
                 └────────┬────────┘
                          │
                          v
              ┌───────────────────────┐
              │ Edit text + toolbar   │
              └───────────────────┬───┘
                                  │
                                  v
                        ┌─────────────────┐
                        │ Save to Drive    │
                        └─────────────────┘

v2 additions (not blocking v1):
- Syntax highlighting (standalone, no dependencies)
- Keyboard shortcuts (enhances editor, no dependencies)
- Find/Replace (standalone, no dependencies)
- Markdown preview (depends on preview renderer, not on v1 features)
- Multiple file tabs (depends on tab UI, not on v1 features)
```

**Critical path for v1:** OAuth → Browse → Open → Edit → Save
**Do NOT build v2 features before v1 ships.** Validate core workflow first.

## MVP Recommendation (v1 — Raw Text Editor)

**Must Have (ship with these):**

1. Google Drive OAuth2 authentication
2. Browse Drive folder hierarchy with dot folder visibility
3. Open and edit markdown files as raw text
4. Formatting toolbar: **bold**, *italic*, # headers (h1-h3), bullet lists, numbered lists
5. Save edits back to Drive atomically
6. File metadata display (path, size, last modified)
7. Sync status indicator (saved / syncing / error states)

**Nice-to-Have (if time, otherwise v1.1):**

- Keyboard shortcuts (Command+B, Command+Z, Command+I, etc.)
- Search/Find within file
- Syntax highlighting (markdown color coding)
- Undo/redo beyond system level

**Explicitly Defer to v2:**

- Markdown preview / rendered output
- Local file caching for offline editing
- Multiple file tabs
- Real-time collaboration
- Custom themes or colors beyond system light/dark mode

## Google Drive-Specific Features

### Required for MVP

| Feature | Rationale | Complexity |
|---------|-----------|------------|
| **Dot folder visibility** | Core differentiator; users expect to see `.planning`, `.claude`, `.git` etc. | High (requires API awareness and UI design) |
| **Full path breadcrumb** | Users navigating deep folder hierarchies need to know where they are | Low |
| **Refresh folder listing** | Drive can change outside the app; pull-to-refresh pattern | Low |
| **File picker fallback** | If custom browser fails, let users pick files via system UIDocumentPickerViewController | Medium |

### Optional for v1, Consider for v1.1

| Feature | Rationale | Complexity |
|---------|-----------|------------|
| **Recent files list** | Quick access to files edited recently in the app (cached) | Low |
| **Google Drive folder shortcuts** | Users with favorite shared drives or folders can pin them | Medium |
| **Storage quota display** | Show how much Drive space is used / available | Low |
| **Starred file filtering** | Show only files user has starred in Drive | Low |

### Explicitly NOT supported in v1

| Anti-Feature | Why |
|--------------|-----|
| **Shared Drive support** | Adds complexity; focus on My Drive first |
| **Shared file permissions editing** | Out of scope; editing, not administration |
| **Version history / rollback** | Drive has this natively; don't duplicate |
| **Upload files from device** | Editing existing files only, not media import |

## Feature Complexity Scale

How to think about build effort:

- **Low** (1-2 days): Text field, simple buttons, file metadata display, basic UI
- **Medium** (3-5 days): OAuth2 flow, file browser with tree navigation, sync indicators, keyboard shortcuts
- **High** (1+ weeks): Dot folder handling in API/UI, markdown preview rendering, offline sync with conflict detection

## Source

Research based on:
- Project requirements (PROJECT.md): dot folder access is differentiator; v1 is raw text only
- iOS markdown editor market patterns (training data): table stakes include editing, saving, formatting toolbar
- Google Drive API capabilities: folder browsing, OAuth2, file metadata, atomic writes
- Competitor analysis implicit in PROJECT.md: existing apps (Markdown Pro) fail because they hide dot folders

**Note:** Full ecosystem validation (feature parity with iA Writer, Ulysses, Bear, Markdown Pro) deferred to Phase 2 research when selecting tech stack. This research focuses on YOUR users' core needs based on the stated problem: dot folder access.

**Confidence level:** MEDIUM
- Project scope is explicit and clear
- Table stakes based on iOS markdown editor conventions
- Google Drive-specific features extrapolated from API capabilities
- Validation loop: ship MVP, gather user feedback, adjust for v1.1
