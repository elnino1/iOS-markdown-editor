---
phase: 05-preview-infrastructure
plan: "01"
subsystem: preview-infrastructure
tags: [tdd, red-phase, css, javascript, xctest, resources]
dependency_graph:
  requires: []
  provides: [MarkdownRendererTests contract, markdown-preview.css, markdown-preview.js]
  affects: [05-02-PLAN (MarkdownRenderer.swift must satisfy these contracts), 05-03-PLAN (PreviewView uses these resources)]
tech_stack:
  added: []
  patterns: [TDD RED phase, XCTest stubs, CSS custom properties, CSS prefers-color-scheme, IIFE JS module pattern]
key_files:
  created:
    - MarkdownEditorTests/MarkdownRendererTests.swift
    - MarkdownEditor/Resources/markdown-preview.css
    - MarkdownEditor/Resources/markdown-preview.js
  modified:
    - MarkdownEditor.xcodeproj/project.pbxproj
decisions:
  - "Tests call MarkdownRenderer.generateHTML(from:) as a static method — this is the contract Plan 02 must implement"
  - "CSS uses CSS custom properties (variables) with prefers-color-scheme media query for automatic dark mode — no UIKit override needed"
  - "JS uses IIFE pattern to avoid global namespace pollution; exposes only window.renderMarkdown"
  - "Resources registered in Copy Bundle Resources build phase so Bundle.main.url(forResource:) will find them at runtime"
metrics:
  duration_seconds: 319
  completed_date: "2026-03-27"
  tasks_completed: 2
  tasks_total: 2
  files_created: 3
  files_modified: 1
---

# Phase 5 Plan 1: TDD Red Phase and Static Resources Summary

**One-liner:** Failing XCTest stubs for all 8 MarkdownRenderer contracts plus complete CSS/JS static assets with prefers-color-scheme dark mode.

---

## What Was Built

**Task 1 — MarkdownRendererTests.swift (RED)**

Created `MarkdownEditorTests/MarkdownRendererTests.swift` with 8 failing test methods that define the contract for `MarkdownRenderer.generateHTML(from:)`:

| Test Method | Requirement | Checks |
|---|---|---|
| `testHeadingsRenderWithVisualHierarchy` | PREV-02 | `<h1>`, `<h2>`, `<h3>` in HTML output |
| `testBoldAndItalicRenderAsStyled` | PREV-03 | `<strong>bold</strong>`, `<em>italic</em>` |
| `testListsRenderWithIndentation` | PREV-04 | `<ul>`, `<li>`, `<ol>` |
| `testCodeBlocksRenderMonospace` | PREV-05 | `<pre><code` |
| `testInlineCodeRendersMonospace` | PREV-06 | `<code>code</code>` |
| `testTablesRenderAsGrid` | PREV-07 | `<table>`, `<th>`, `<td>` |
| `testDarkModeCSS` | PREV-09 | `prefers-color-scheme` in HTML |
| `testMarkdownRendererInitializes` | — | `MarkdownRenderer()` instantiation |

All tests reference `MarkdownRenderer.generateHTML(from:)` (static method returning `String`) which does not exist. Build fails with "cannot find 'MarkdownRenderer' in scope" x8 — confirming RED state.

**Task 2 — markdown-preview.css and markdown-preview.js**

Created `MarkdownEditor/Resources/markdown-preview.css`:
- CSS custom properties in `:root` (7 color variables)
- `@media (prefers-color-scheme: dark)` block with dark theme values
- Typography: -apple-system font stack, 16px base, 1.6 line height
- Heading hierarchy: 2em / 1.5em / 1.25em
- Code/pre: Menlo/Monaco monospace, border + background
- Tables: border-collapse, full width, `<th>` styled
- highlight.js token colors for light and dark

Created `MarkdownEditor/Resources/markdown-preview.js`:
- IIFE module pattern
- Initializes `window.markdownit()` with `html: false, linkify: false`
- Conditional `markdown-it-table` plugin registration
- Conditional `highlight.js` integration with per-language highlighting
- Exposes `window.renderMarkdown(markdownText)` — renders into `#content` div

Both files registered in Xcode project: file references created, `Resources/` group added under `MarkdownEditor` group, both included in `Copy Bundle Resources` build phase for the `MarkdownEditor` target.

---

## Deviations from Plan

**1. [Rule 1 - Bug] Test file not included in Xcode project after file creation**

- **Found during:** Task 1 verification
- **Issue:** Creating `MarkdownRendererTests.swift` on disk alone did not make the build fail — Xcode didn't know about the file. Build succeeded (wrong result for RED phase).
- **Fix:** Manually edited `project.pbxproj` to add PBXBuildFile entry, PBXFileReference entry, group membership under `MarkdownEditorTests`, and Sources build phase entry.
- **Files modified:** `MarkdownEditor.xcodeproj/project.pbxproj`
- **Commit:** 78aa4de

No other deviations — plan executed as written.

---

## Self-Check

Files exist:

- [x] `MarkdownEditorTests/MarkdownRendererTests.swift` — FOUND
- [x] `MarkdownEditor/Resources/markdown-preview.css` — FOUND
- [x] `MarkdownEditor/Resources/markdown-preview.js` — FOUND

Commits exist:

- [x] 78aa4de — test(05-01): add failing MarkdownRendererTests.swift stubs (RED)
- [x] acbc890 — feat(05-01): add markdown-preview.css and markdown-preview.js resource files

Build state:

- [x] Build fails with "cannot find 'MarkdownRenderer' in scope" x8 — RED state confirmed

## Self-Check: PASSED
