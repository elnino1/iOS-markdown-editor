# Milestones

## v1.1 Formatting Toolbar (Shipped: 2026-03-27)

**Phases:** 4 | **Plans:** 3 | **Timeline:** 2 days (2026-03-26 → 2026-03-27)

**Key accomplishments:**

- XCTest scaffolding: 16 failing stubs across 3 files covering all 8 requirements (Wave 0 TDD)
- FormattingService: pure enum with bold/italic/bullet/table via UITextInput protocol, atomic undo grouping
- Keyboard toolbar: 7-button UIToolbar docked above keyboard via inputAccessoryView, undo/redo state management
- Toggle-off behavior: bold/italic/bullet detect existing formatting and strip markers instead of double-wrapping
- Undo integrity: all operations use UITextInput replace/insertText (never textStorage), preserving the undo stack

**Archive:** `.planning/milestones/v1.1-ROADMAP.md`

---

## v1.0 MVP (Shipped: 2026-03-26)

**Phases:** 1-3 | **Plans:** 9 | **Timeline:** 1 day (2026-03-25 → 2026-03-26)

**Key accomplishments:**

- Core file loop: open via picker + "Open With", edit raw text, auto-save back to original location
- UIDocument-based architecture: proper iOS file coordination, works with any file source including dot folders
- Syntax highlighting: regex-based HighlightingService with 5 patterns, ThemeColors for light/dark
- Unsaved indicator, light/dark mode, error handling, large file warnings, recently opened files list

---
