---
plan: 04-03
status: complete
completed: 2026-03-27
---

# Plan 04-03 Summary: EditorView Toolbar UI

## What was built
7-button formatting toolbar docked above the iOS keyboard via `UITextView.inputAccessoryView` (UIToolbar). Buttons: Bold, Italic, Bullet, Table, Undo, Redo, Keyboard Dismiss. Undo/Redo gray out when stacks are empty.

## Commits
- `ceb58dc` fix(04-03): use UITextView.inputAccessoryView for keyboard toolbar
- `ab73723` fix(04-03): call scrollRangeToVisible after restoring selectedRange
- `35ff827` fix(04-03): disable undo registration during syntax highlighting updates (reverted)
- `9155af9` fix(04-03): use textStorage for highlighting to preserve undo stack (partial fix)
- `cd262c1` fix(04-03): update highlighting via attribute enumeration to preserve undo stack
- `eed2976` fix(04-03): replace UIColor.systemBlue with Color.blue in toolbar buttons

## Key deviations from plan
1. **SwiftUI .toolbar(placement: .keyboard) doesn't work with UIViewRepresentable** — replaced with `UITextView.inputAccessoryView` + `UIToolbar` directly
2. **Highlighting debounce wiped undo stack** — `setAttributedString` / `attributedText` both replace character data and reset `NSUndoManager`. Fixed by enumerating and setting attributes only (no character replacement)
3. **scrollRangeToVisible required** — setting `attributedText`/`textStorage` resets scroll; must explicitly call `scrollRangeToVisible` after restoring `selectedRange`

## Human checkpoint
Approved 2026-03-27. All 12 verification steps passed.
