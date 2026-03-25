# Requirements: iOS Markdown Editor

**Defined:** 2026-03-25
**Core Value:** Users can browse, edit, and save markdown files anywhere in their Google Drive — including dot folders that other apps hide.

## v1 Requirements

### Authentication

- [ ] **AUTH-01**: User can sign in with their Google account (OAuth 2.0)
- [ ] **AUTH-02**: User stays signed in across app restarts
- [ ] **AUTH-03**: User can sign out

### File Browser

- [ ] **BROW-01**: User can browse Google Drive folder hierarchy including dot folders (e.g. `.claude`, `.planning`)
- [ ] **BROW-02**: User can navigate into subfolders
- [ ] **BROW-03**: Only `.md` files are shown in folder listings (folders always visible)

### Editor

- [ ] **EDIT-01**: User can open a markdown file and edit it as raw text
- [ ] **EDIT-02**: User can save edits back to the original file in Google Drive
- [ ] **EDIT-03**: App shows a visual indicator when there are unsaved changes
- [ ] **EDIT-04**: Editor applies markdown syntax coloring

### Appearance

- [ ] **APPR-01**: App supports light and dark mode

## v2 Requirements

### Editor Enhancements

- **EDIT-V2-01**: Formatting toolbar (bold, italic, H1-H3, bullet list, numbered list)
- **EDIT-V2-02**: Markdown preview / rendered output toggle

## Out of Scope

| Feature | Reason |
|---------|--------|
| Note-taking / organization features | This is an editor, not a notes app |
| Local file storage | Drive-only; no local persistence of markdown content |
| WYSIWYG editing | Deferred to v2+ |
| iCloud / Dropbox / other storage | Google Drive only for v1 |
| Real-time collaboration | Out of scope; single-user editing |
| Offline editing | Network required; conflict resolution too complex for v1 |
| App Store publishing | Personal use first |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| AUTH-01 | Phase 1 | Pending |
| AUTH-02 | Phase 1 | Pending |
| AUTH-03 | Phase 1 | Pending |
| BROW-01 | Phase 2 | Pending |
| BROW-02 | Phase 2 | Pending |
| BROW-03 | Phase 2 | Pending |
| EDIT-01 | Phase 3 | Pending |
| EDIT-02 | Phase 4 | Pending |
| EDIT-03 | Phase 3 | Pending |
| EDIT-04 | Phase 3 | Pending |
| APPR-01 | Phase 3 | Pending |

**Coverage:**
- v1 requirements: 11 total
- Mapped to phases: 11
- Unmapped: 0 ✓

---

*Requirements defined: 2026-03-25*
*Last updated: 2026-03-25 after roadmap creation*
