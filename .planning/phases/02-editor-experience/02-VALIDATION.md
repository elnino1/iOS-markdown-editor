---
phase: 2
slug: editor-experience
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-25
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (built into Xcode) |
| **Config file** | MarkdownEditorTests/ — Wave 0 creates |
| **Quick run command** | `xcodebuild test -scheme MarkdownEditor -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -5` |
| **Full suite command** | `xcodebuild test -scheme MarkdownEditor -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick run command
- **After every plan wave:** Run full suite command
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 2-01-01 | 01 | 1 | EDIT-04 | unit | `xcodebuild test -scheme MarkdownEditor -only-testing:MarkdownEditorTests/MarkdownHighlighterTests` | ❌ W0 | ⬜ pending |
| 2-01-02 | 01 | 1 | EDIT-04 | unit | `xcodebuild test -scheme MarkdownEditor -only-testing:MarkdownEditorTests/MarkdownHighlighterTests` | ❌ W0 | ⬜ pending |
| 2-02-01 | 02 | 2 | EDIT-03 | unit | `xcodebuild test -scheme MarkdownEditor -only-testing:MarkdownEditorTests/UnsavedChangesTests` | ❌ W0 | ⬜ pending |
| 2-02-02 | 02 | 2 | APPR-01 | manual | N/A — visual verification | N/A | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `MarkdownEditorTests/MarkdownHighlighterTests.swift` — stubs for EDIT-04 (syntax coloring)
- [ ] `MarkdownEditorTests/UnsavedChangesTests.swift` — stubs for EDIT-03 (change indicator)
- [ ] `MarkdownEditorTests/MarkdownEditorTests.swift` — test target bootstrap if not present

*Wave 0 must be committed before Wave 1 plan execution begins.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Syntax colors visually distinct in light mode | EDIT-04 | Color rendering requires visual inspection | Open .md file with headings, bold, italic, code, links — verify each has distinct color |
| Syntax colors visually distinct in dark mode | EDIT-04 | Color rendering requires visual inspection | Toggle to dark mode, verify same elements still visually distinct |
| App correct in both light and dark mode | APPR-01 | Appearance requires visual inspection | Toggle appearance in Settings → verify no broken colors across HomeView and EditorView |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
