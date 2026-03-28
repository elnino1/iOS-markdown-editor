---
phase: 5
slug: preview-infrastructure
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-27
---

# Phase 5 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (built-in) |
| **Config file** | none — XCTest is part of Xcode project |
| **Quick run command** | `xcodebuild test -scheme MarkdownEditor -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:MarkdownEditorTests` |
| **Full suite command** | `xcodebuild test -scheme MarkdownEditor -destination 'platform=iOS Simulator,name=iPhone 16'` |
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
| 5-xx-01 | 01 | 1 | PREV-02 | unit | `xcodebuild test -only-testing:MarkdownEditorTests/MarkdownRendererTests/testHeadings` | ❌ W0 | ⬜ pending |
| 5-xx-02 | 01 | 1 | PREV-03 | unit | `xcodebuild test -only-testing:MarkdownEditorTests/MarkdownRendererTests/testEmphasis` | ❌ W0 | ⬜ pending |
| 5-xx-03 | 01 | 1 | PREV-04 | unit | `xcodebuild test -only-testing:MarkdownEditorTests/MarkdownRendererTests/testLists` | ❌ W0 | ⬜ pending |
| 5-xx-04 | 01 | 1 | PREV-05 | unit | `xcodebuild test -only-testing:MarkdownEditorTests/MarkdownRendererTests/testCodeBlocks` | ❌ W0 | ⬜ pending |
| 5-xx-05 | 01 | 1 | PREV-06 | unit | `xcodebuild test -only-testing:MarkdownEditorTests/MarkdownRendererTests/testTables` | ❌ W0 | ⬜ pending |
| 5-xx-06 | 01 | 1 | PREV-07 | unit | `xcodebuild test -only-testing:MarkdownEditorTests/MarkdownRendererTests/testLinks` | ❌ W0 | ⬜ pending |
| 5-xx-07 | 01 | 1 | PREV-09 | manual | Dark mode toggle + visual inspect | — | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `MarkdownEditorTests/MarkdownRendererTests.swift` — test stubs for PREV-02 through PREV-07
- [ ] `MarkdownEditorTests/MarkdownRendererTests.swift` — shared test fixtures (sample markdown strings)

*Existing XCTest infrastructure covers the framework; new test file needed for renderer coverage.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Rendered HTML matches system dark mode | PREV-09 | WKWebView CSS media query response requires visual inspection | Toggle system appearance in Settings > Display & Brightness, verify preview background/text colors update without app restart |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
