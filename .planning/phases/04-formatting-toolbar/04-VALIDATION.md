---
phase: 4
slug: formatting-toolbar
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-03-26
---

# Phase 4 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest |
| **Config file** | iOS-markdown-editor.xcodeproj |
| **Quick run command** | `xcodebuild test -scheme iOS-markdown-editor -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:iOS-markdown-editorTests 2>&1 | tail -20` |
| **Full suite command** | `xcodebuild test -scheme iOS-markdown-editor -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -30` |
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
| 4-01-01 | 01 | 1 | TOOL-01 | unit | `xcodebuild test ... -only-testing:iOS-markdown-editorTests/FormattingToolbarTests/testToolbarAppearsAboveKeyboard` | ❌ W0 | ⬜ pending |
| 4-01-02 | 01 | 1 | TOOL-02 | unit | `xcodebuild test ... -only-testing:iOS-markdown-editorTests/FormattingToolbarTests/testKeyboardDismissButton` | ❌ W0 | ⬜ pending |
| 4-02-01 | 02 | 2 | FMT-01 | unit | `xcodebuild test ... -only-testing:iOS-markdown-editorTests/FormattingOperationsTests/testBoldWrapsSelectedText` | ❌ W0 | ⬜ pending |
| 4-02-02 | 02 | 2 | FMT-01 | unit | `xcodebuild test ... -only-testing:iOS-markdown-editorTests/FormattingOperationsTests/testBoldInsertsAtCursor` | ❌ W0 | ⬜ pending |
| 4-02-03 | 02 | 2 | FMT-02 | unit | `xcodebuild test ... -only-testing:iOS-markdown-editorTests/FormattingOperationsTests/testItalicWrapsSelectedText` | ❌ W0 | ⬜ pending |
| 4-02-04 | 02 | 2 | FMT-02 | unit | `xcodebuild test ... -only-testing:iOS-markdown-editorTests/FormattingOperationsTests/testItalicInsertsAtCursor` | ❌ W0 | ⬜ pending |
| 4-02-05 | 02 | 2 | FMT-03 | unit | `xcodebuild test ... -only-testing:iOS-markdown-editorTests/FormattingOperationsTests/testBulletPrefixesLine` | ❌ W0 | ⬜ pending |
| 4-02-06 | 02 | 2 | FMT-04 | unit | `xcodebuild test ... -only-testing:iOS-markdown-editorTests/FormattingOperationsTests/testTableInsertsTemplate` | ❌ W0 | ⬜ pending |
| 4-03-01 | 03 | 2 | UNDO-01 | unit | `xcodebuild test ... -only-testing:iOS-markdown-editorTests/UndoRedoTests/testUndoRevertsFormatting` | ❌ W0 | ⬜ pending |
| 4-03-02 | 03 | 2 | UNDO-02 | unit | `xcodebuild test ... -only-testing:iOS-markdown-editorTests/UndoRedoTests/testRedoReappliesFormatting` | ❌ W0 | ⬜ pending |
| 4-03-03 | 03 | 2 | UNDO-01 | unit | `xcodebuild test ... -only-testing:iOS-markdown-editorTests/UndoRedoTests/testBoldIsAtomicUndo` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `iOS-markdown-editorTests/FormattingOperationsTests.swift` — stubs for FMT-01, FMT-02, FMT-03, FMT-04
- [ ] `iOS-markdown-editorTests/UndoRedoTests.swift` — stubs for UNDO-01, UNDO-02
- [ ] `iOS-markdown-editorTests/FormattingToolbarTests.swift` — stubs for TOOL-01, TOOL-02 (integration/UI tests)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Toolbar appears above keyboard on device | TOOL-01 | Keyboard inputAccessoryView requires real keyboard interaction | Run app, tap editor, verify toolbar is visible above keyboard |
| Toolbar dismisses with keyboard | TOOL-01 | Dismiss event requires real UI interaction | Tap keyboard dismiss button, verify toolbar and keyboard both hide |
| Emoji character boundaries | FMT-01, FMT-02 | Multi-byte edge cases best caught in real UI | Type emoji, select, apply bold — verify no corruption |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
