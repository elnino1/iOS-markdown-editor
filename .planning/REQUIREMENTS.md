# Requirements: iOS Markdown Editor

**Defined:** 2026-03-25
**Updated:** 2026-03-25 (architectural pivot — removed Drive API/OAuth, adopted document sharing)
**Core Value:** A focused markdown editor that works with any file source — open from anywhere, edit, save back.

## v1 Requirements

### File Access

- [x] **FILE-01**: User can open a markdown file using the in-app file picker (UIDocumentPickerViewController)
- [x] **FILE-02**: User can open a markdown file via "Open With" from another app (Google Drive, Files app, etc.)

### Editor

- [x] **EDIT-01**: User can edit the opened file as raw text
- [x] **EDIT-02**: User can save edits back to the original file location
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
| Google Drive API / OAuth | Not needed — user opens files via "Open With" from Google Drive app |
| Built-in Drive folder browser | User browses in Google Drive app (shows all folders incl. dot folders) |
| Note-taking / organization features | This is an editor, not a notes app |
| WYSIWYG editing | Deferred to v2+ |
| Real-time collaboration | Out of scope |
| Offline editing | Handled by source app (Google Drive app has offline mode) |
| App Store publishing | Personal use first |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| FILE-01 | Phase 1 | Complete |
| FILE-02 | Phase 1 | Complete |
| EDIT-01 | Phase 1 | Complete |
| EDIT-02 | Phase 1 | Complete |
| EDIT-03 | Phase 2 | Pending |
| EDIT-04 | Phase 2 | Pending |
| APPR-01 | Phase 2 | Pending |

**Coverage:**
- v1 requirements: 7 total
- Mapped to phases: 7
- Unmapped: 0 ✓

---
*Requirements defined: 2026-03-25*
*Last updated: 2026-03-25 after architectural pivot*
