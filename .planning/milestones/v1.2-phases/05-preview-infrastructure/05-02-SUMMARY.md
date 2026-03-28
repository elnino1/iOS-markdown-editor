---
phase: 05-preview-infrastructure
plan: "02"
subsystem: preview-infrastructure
tags: [tdd, green-phase, javascript-core, markdown-it, xctest, ios, swift]

# Dependency graph
requires:
  - phase: 05-01
    provides: "MarkdownRendererTests.swift contract, markdown-preview.css, markdown-preview.js in Copy Bundle Resources"
provides:
  - "MarkdownRenderer.swift with static generateHTML(from:) — synchronous markdown → HTML via JavaScriptCore"
  - "markdown-it@14.1.1 bundled in app (markdown-it.min.js)"
  - "markdown-it-multimd-table@4.2.3 bundled in app (markdown-it-table.min.js)"
  - "All 8 MarkdownRendererTests passing GREEN"
affects: [05-03-PLAN (PreviewView loads HTML from MarkdownRenderer.generateHTML), 06-PLAN (preview toggle integration)]

# Tech tracking
tech-stack:
  added: [JavaScriptCore, markdown-it@14.1.1, markdown-it-multimd-table@4.2.3]
  patterns:
    - "JSContext singleton (static let) for synchronous markdown-it execution without WKWebView"
    - "Bundle(for: MarkdownRenderer.self) instead of Bundle.main for unit-test bundle compatibility"
    - "UMD shims (window/module/exports) so markdown-it UMD bundle works in JSContext"
    - "Array-wrap JSON encoding: wrap string in array, serialize, strip outer brackets"

key-files:
  created:
    - MarkdownEditor/MarkdownRenderer.swift
    - MarkdownEditor/Resources/markdown-it.min.js
    - MarkdownEditor/Resources/markdown-it-table.min.js
  modified:
    - MarkdownEditor.xcodeproj/project.pbxproj

key-decisions:
  - "Bundle(for: MarkdownRenderer.self) required instead of Bundle.main — unit tests run in test bundle, not app bundle, so Bundle.main cannot find app resources"
  - "jsonEncoded() wraps string in array before JSONSerialization — String is not a valid top-level JSON type in the non-fragmentsAllowed API"
  - "JSContext UMD shims (var window = this; var module = {exports: {}}; var exports = module.exports;) required for markdown-it UMD bundle to execute in JSContext"
  - "markdown-it@14.1.1 has no built-in table support — markdown-it-multimd-table@4.2.3 plugin loaded via md.use() in JSContext"
  - "module.exports is reset between UMD bundle evaluations to prevent one plugin's export from polluting the next"

patterns-established:
  - "UMD shim pattern for JSContext: always add window/self/globalThis/module/exports shims before evaluating any UMD bundle"
  - "After each UMD bundle: capture the export (markdownitLib = module.exports || global.markdownit), then reset module for next bundle"
  - "Bundle resource access in testable Swift: always use Bundle(for: SomeClass.self) not Bundle.main"

requirements-completed: [PREV-02, PREV-03, PREV-04, PREV-05, PREV-06, PREV-07]

# Metrics
duration: 48min
completed: "2026-03-27"
---

# Phase 5 Plan 2: MarkdownRenderer GREEN Phase Summary

**Synchronous markdown-to-HTML via JavaScriptCore singleton running markdown-it@14.1.1 with multimd-table plugin — all 8 MarkdownRendererTests pass GREEN.**

## Performance

- **Duration:** 48 min
- **Started:** 2026-03-27T21:24:46Z
- **Completed:** 2026-03-27T22:13:30Z
- **Tasks:** 1
- **Files modified:** 4

## Accomplishments

- Implemented `MarkdownRenderer.swift` with `static func generateHTML(from:)` using JavaScriptCore for synchronous markdown rendering
- Downloaded and bundled `markdown-it@14.1.1` (123KB) and `markdown-it-multimd-table@4.2.3` (6KB) plugin
- Fixed two bugs (Bundle.main and JSON encoding) discovered during test execution
- All 8 `MarkdownRendererTests` pass GREEN: headings, bold/italic, lists, code blocks, inline code, tables, dark mode CSS, initialization

## Task Commits

Each task was committed atomically:

1. **Task 1: MarkdownRenderer.swift (RED → GREEN)** — `f21b8d0` (feat)

**Plan metadata:** committed with SUMMARY

## Files Created/Modified

- `MarkdownEditor/MarkdownRenderer.swift` — Static HTML generator using JSContext + markdown-it; singleton JS context loaded once on first call
- `MarkdownEditor/Resources/markdown-it.min.js` — markdown-it@14.1.1 UMD bundle (123KB); parsed by JSContext at runtime
- `MarkdownEditor/Resources/markdown-it-table.min.js` — markdown-it-multimd-table@4.2.3 plugin (6KB); registered via `md.use()` in JSContext
- `MarkdownEditor.xcodeproj/project.pbxproj` — New file references, group membership, Sources build phase (MarkdownRenderer.swift), Copy Bundle Resources (JS files)

## Decisions Made

- **Bundle(for:) over Bundle.main:** Unit tests inject into `MarkdownEditorTests.xctest` bundle; `Bundle.main` returns the test runner bundle which has no app resources. `Bundle(for: MarkdownRenderer.self)` resolves to the `MarkdownEditor.app` bundle where JS/CSS files live.
- **Array-wrap JSON encoding:** `JSONSerialization.data(withJSONObject: string)` crashes with "Invalid top-level type" on iOS because `String` is not a valid JSON root. Fix: serialize `[string]` then strip outer `[` and `]`.
- **markdown-it-multimd-table over simpler alternatives:** Plan specified this plugin. It provides GFM-style `|---|` table parsing that the tests assert on.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Bundle.main returns wrong bundle in unit test context**
- **Found during:** Task 1 — first test run showed 7/8 failures
- **Issue:** `Bundle.main` in the test context is the XCTest runner bundle, not `MarkdownEditor.app`. `Bundle.main.url(forResource: "markdown-it.min", withExtension: "js")` returned `nil`, so the JSContext was initialized without markdown-it. `renderToHTML()` returned `"<p>Error: markdown-it not loaded</p>"` for all calls.
- **Fix:** Changed all `Bundle.main` references to `Bundle(for: MarkdownRenderer.self)` via a `private static let resourceBundle` property. This resolves to the bundle containing the compiled `MarkdownRenderer` class — i.e., `MarkdownEditor.app` — in both app and test contexts.
- **Files modified:** `MarkdownEditor/MarkdownRenderer.swift`
- **Verification:** Tests still failed after this fix (second root cause existed)
- **Committed in:** f21b8d0 (Task 1 commit, combined with fix 2)

**2. [Rule 1 - Bug] jsonEncoded() crashes with NSInvalidArgumentException for String top-level value**
- **Found during:** Task 1 — second test run (after fix 1), failure messages extracted from xcresult showed "Invalid top-level type in JSON write"
- **Issue:** `JSONSerialization.data(withJSONObject: self)` where `self` is a `String` throws `NSInvalidArgumentException` — the API requires `NSArray` or `NSDictionary` at the top level. The method silently fell through to `?? "\"\""`, causing `renderToHTML("")` to be called with an empty string, returning an empty HTML body, failing all content assertions.
- **Fix:** Changed `jsonEncoded()` to serialize `[self]` (wrapping in array), then strip the surrounding `[` and `]` to produce the quoted string literal. This is correct and handles all Unicode/escape scenarios via JSONSerialization.
- **Files modified:** `MarkdownEditor/MarkdownRenderer.swift`
- **Verification:** All 8 tests pass after fix
- **Committed in:** f21b8d0 (Task 1 commit)

---

**Total deviations:** 2 auto-fixed (both Rule 1 - Bug)
**Impact on plan:** Both bugs were in the initial implementation of `MarkdownRenderer.swift` (the implementation existed before this plan executed). Both fixes necessary for correctness. No scope creep.

## Issues Encountered

- The files (`MarkdownRenderer.swift`, `markdown-it.min.js`, `markdown-it-table.min.js`) and Xcode project registration already existed on disk when this plan executed — created during an earlier work session. No re-download needed, no re-registration needed. This plan focused on making tests pass GREEN.
- iPhone 16 simulator not available; used iPhone 17 instead. No functional difference for these unit tests.

## Next Phase Readiness

- `MarkdownRenderer.generateHTML(from:)` fully tested — ready for Plan 03 (PreviewView) to call it and load the HTML string into `WKWebView`
- CSS with `prefers-color-scheme` is embedded via the static `cssContent` property — no changes needed for dark mode
- Table rendering works via markdown-it-multimd-table plugin

## Self-Check: PASSED

- [x] `MarkdownEditor/MarkdownRenderer.swift` — FOUND
- [x] `MarkdownEditor/Resources/markdown-it.min.js` — FOUND (123KB > 50KB)
- [x] `MarkdownEditor/Resources/markdown-it-table.min.js` — FOUND
- [x] `.planning/phases/05-preview-infrastructure/05-02-SUMMARY.md` — FOUND
- [x] `import JavaScriptCore` in MarkdownRenderer.swift — FOUND
- [x] `static func generateHTML(from markdown: String) -> String` — FOUND
- [x] `prefers-color-scheme` in markdown-preview.css — FOUND
- [x] Commit f21b8d0 — FOUND
- [x] 8/8 MarkdownRendererTests pass GREEN — CONFIRMED

---
*Phase: 05-preview-infrastructure*
*Completed: 2026-03-27*
