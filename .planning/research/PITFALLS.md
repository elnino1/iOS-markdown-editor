# Domain Pitfalls: Adding Formatting Toolbar to UITextView-Based Markdown Editor

**Domain:** iOS text editing with formatting toolbar (bold, italic, bullets, tables)
**Context:** Retrofitting formatting toolbar into existing UITextView editor with NSAttributedString syntax highlighting, Combine-based auto-save, and UIDocument undo management
**Researched:** 2026-03-26
**Confidence:** HIGH (combination of official Apple docs, developer forum discussions, and real-world implementation experience)

---

## Critical Pitfalls (Rewrite Risk)

### Pitfall 1: Undo Stack Invalidation via Direct Text Storage Modification

**What goes wrong:**
Toolbar formatting code modifies `UITextView.textStorage` directly (inserting `**text**` wrapper, prefixing `- ` bullets, etc.) without registering undo operations. Result: undo/redo stack becomes inconsistent. User presses Undo and sees the text change but not the formatting toolbar state, or undo corrupts the attributed string highlighting state.

**Why it happens:**
Direct `textStorage.addAttribute()` or text replacement bypasses the undo manager. The UITextView expects text changes to flow through `UITextInput` protocol methods, not raw `NSTextStorage` mutations. Developers often assume that since they're modifying the text, the undo manager will track it—but it doesn't. Worse: if toolbar code and syntax highlighting both modify textStorage simultaneously, they can fight each other.

**Consequences:**
- Undo/Redo buttons trigger erratic behavior
- User loses trust in editor reliability
- May corrupt document state requiring reload
- Syntax highlighting may desync with undo (attributes removed but text kept)
- Multiple undo/redo actions get collapsed or duplicated

**Prevention:**
1. **Use UITextInput methods for text insertion:**
   ```swift
   // ❌ BAD: Direct modification bypasses undo
   textView.textStorage.replaceCharacters(in: range, with: "**\(selected)**")

   // ✓ GOOD: Via UITextInput (which registers undo)
   let oldSelection = textView.selectedRange
   textView.undoManager?.beginUndoGrouping()
   insertText("**", at: range.location)
   insertText("**", at: range.location + range.length + 2)
   textView.undoManager?.endUndoGrouping()
   textView.selectedRange = NSRange(location: oldSelection.location + 2, length: oldSelection.length)
   ```

2. **For attribute-only changes (no text change):**
   ```swift
   // Register undo BEFORE modification
   let undoManager = textView.undoManager
   undoManager?.beginUndoGrouping()

   // Make the change to textStorage
   let oldRange = NSRange(location: 0, length: textView.text.count)
   let oldAttributedText = NSAttributedString(attributedString: textView.attributedText)

   // Register undo action to restore attributes
   undoManager?.registerUndo(withTarget: textView) { target in
       target.attributedText = oldAttributedText
   }

   // Apply new attributes
   textView.textStorage.addAttribute(.foregroundColor, value: UIColor.red, range: range)

   undoManager?.endUndoGrouping()
   undoManager?.setActionName("Apply Bold")
   ```

3. **Group toolbar operations atomically:**
   ```swift
   // If bold wrapping is: insert "**" at start, then at end
   // Both operations must be in one undo group so they undo together
   textView.undoManager?.beginUndoGrouping()

   let startPosition = selectedRange.location
   insertText("**", at: startPosition)

   let endPosition = startPosition + selectedRange.length + 2
   insertText("**", at: endPosition)

   textView.undoManager?.endUndoGrouping()
   textView.undoManager?.setActionName("Make Bold")
   ```

4. **Never modify textStorage during textViewDidChange callback:**
   - This callback fires from UITextView's own state updates
   - Modifying textStorage here creates feedback loops
   - Move formatting to separate method called AFTER delegate callback completes

**Detection:**
- User applies formatting, presses Undo, formatting disappears but text doesn't revert
- Undo stack grows incorrectly (toolbar actions not appearing as separate undo steps)
- After undo, selected range is wrong or text is corrupted
- Rapid toolbar clicks create weird interleaved undo states

**Risk if missed:** CRITICAL — document integrity + UX trust destroyed

---

### Pitfall 2: Cursor Position Loss After NSRange-Based Text Insertion

**What goes wrong:**
Toolbar inserts text at `selectedRange.location` (e.g., user presses Bold, wraps text with `**`). The insertion changes the text length, but cursor position jumps to the end of inserted text instead of staying logically at the original selection boundary. User expected cursor after closing `**` marker; instead it's at end of document. This is especially visible with multi-step formatting (bold wrapping requires TWO insertions).

**Why it happens:**
`NSRange` is a linear index (location + length). When you insert at position 10, all subsequent positions shift. If you insert twice (opening and closing markers), the second insertion's position calculation is wrong because the first one shifted everything. Additionally, `UITextView.selectedRange` assignment doesn't always take effect immediately if done during text modification callbacks or if the text view is not first responder.

**Consequences:**
- User types more text and it goes in the wrong place
- Selection is lost (expected: "text" selected after wrapping, actual: cursor at end)
- Compound actions (bold + additional formatting) fail silently
- User thinks toolbar is broken
- Rapid toolbar clicks leave cursor in random positions

**Prevention:**
1. **Save selection BEFORE any modification, recalculate offsets, restore AFTER:**
   ```swift
   let originalLocation = textView.selectedRange.location
   let originalLength = textView.selectedRange.length

   // Insert opening marker at selection start
   let openingMarkerLength = 2 // "**"
   insertTextAtLocation(originalLocation, text: "**")

   // Insert closing marker at ADJUSTED selection end
   // Original end is now shifted by opening marker
   let newEndPosition = originalLocation + originalLength + openingMarkerLength
   insertTextAtLocation(newEndPosition, text: "**")

   // Restore selection: inside the markers
   // Position has shifted, so adjust both location and length
   textView.selectedRange = NSRange(
     location: originalLocation + openingMarkerLength,
     length: originalLength
   )
   ```

2. **Use beginUndoGrouping to make multi-step insertion atomic:**
   ```swift
   textView.undoManager?.beginUndoGrouping()

   let oldRange = textView.selectedRange
   let selected = (textView.text as NSString).substring(with: oldRange)
   let wrapped = "**\(selected)**"

   // Single operation: replace selection
   replaceTextInRange(oldRange, withText: wrapped)

   // Undo will revert entire operation as one step
   textView.undoManager?.endUndoGrouping()
   textView.undoManager?.setActionName("Make Bold")

   // Restore cursor AFTER grouping and after text is stable
   textView.selectedRange = NSRange(
     location: oldRange.location + 2,
     length: oldRange.length
   )
   ```

3. **For multi-line operations (bullets, tables), work line-by-line with position tracking:**
   ```swift
   // Bullet list: each line gets "- " prefix
   let nsString = textView.text as NSString
   var currentOffset = 0

   let lines = nsString.components(separatedBy: "\n")
   var result = ""

   for (index, line) in lines.enumerated() {
       result += "- " + line
       if index < lines.count - 1 {
           result += "\n"
       }
   }

   // Replace entire selection as one operation
   textView.undoManager?.beginUndoGrouping()
   textView.text = result
   textView.undoManager?.endUndoGrouping()
   ```

4. **Do NOT modify text while in updateUIView():**
   - This callback is triggered by Binding updates; modifying text there creates feedback loops
   - The state update will trigger updateUIView() again, creating recursion
   - Save position in a separate state variable; apply changes via a separate method
   - Example: toolbar button calls a method on a Coordinator that stores the position, then applies formatting after current render pass completes

**Detection:**
- After toolbar action, cursor jumps to end of text
- Rapid toolbar clicks fail (second action in wrong position or nowhere)
- User selects text, applies formatting, selection is gone and cursor is at end
- Text is inserted but in wrong location (position 0, or end of doc)

**Risk if missed:** HIGH — core toolbar feature becomes unreliable

---

### Pitfall 3: Attributed String Highlighting + Text Insertion = Attribute Loss or Double-Formatting

**What goes wrong:**
After user taps Bold button and text is inserted with markers `**text**`, the syntax highlighting service re-scans the entire document. During re-highlighting, NSRegularExpression pattern matching now matches the NEW `**text**` pattern and applies bold styling—but the toolbar's text insertion happened via UITextInput (which is text-only). Worse scenarios:

1. **Attributes lost:** Re-highlighting completely replaces NSAttributedString via `attributedText =` assignment, losing any transient formatting or selection
2. **Double-formatting:** Both toolbar logic (if it sets attributes) and syntax highlighting apply bold, causing visual corruption
3. **Selection reset:** Re-highlighting reassigns `attributedText`, resetting `selectedRange` to position 0
4. **Stale highlighting:** Highlighting service doesn't re-run immediately after toolbar action, so user sees raw `**text**` for 300ms, then formatting appears

**Why it happens:**
In the current implementation (`MarkdownTextEditor.updateUIView`), when text changes, a debounced call to `HighlightingService.applyMarkdownColors()` creates a NEW `NSMutableAttributedString` and assigns it to `textView.attributedText`. This assignment:
- Replaces the entire attributed string (losing transient toolbar formatting)
- Can reset `selectedRange` to 0 (guarded by code, but it's fragile)
- Can trigger `textViewDidChange` again if not careful (feedback loop)
- Happens after a 300ms delay, so user sees unformatted text briefly

**Consequences:**
- Toolbar formatting appears for a moment (raw `**text**`), then syntax highlighting applies bold styling
- Visual flicker: text shows unformatted, then formatted
- If multiple toolbar actions happen rapidly, highlighting might miss one
- Performance: re-highlighting entire file on every keystroke is expensive
- User edits are lost if highlighting replacement happens during editing

**Prevention:**
1. **Preserve selection during re-highlighting (already done, but verify):**
   ```swift
   // Current code in MarkdownTextEditor does this:
   let selectedRange = tv.selectedRange
   tv.attributedText = HighlightingService.applyMarkdownColors(to: text, baseFont: font)
   tv.selectedRange = selectedRange  // Restore ✓
   ```
   This is correct and **already in place**. Verify it's never bypassed.

2. **Apply highlighting ONLY after stable text state:**
   ```swift
   // In EditorView.scheduleSave():
   // Only trigger highlighting after user stops typing (1.5s debounce)
   // NOT immediately on every textViewDidChange

   // Current code already does this via highlightTimer debounce ✓
   ```

3. **For toolbar actions, do NOT trigger highlighting immediately:**
   ```swift
   // In MarkdownTextEditor.Coordinator:
   // When toolbar action fires, skip re-highlighting this keystroke

   @State private var skipHighlightingNextChange = false

   func insertBold() {
       skipHighlightingNextChange = true
       textView.insertText("**selected**")
       // textViewDidChange fires, but we skip highlighting
       // Highlighting resumes after normal delay (300ms with next keystroke)
   }

   func textViewDidChange(_ textView: UITextView) {
       text = textView.text

       guard isHighlightingEnabled && !skipHighlightingNextChange else {
           skipHighlightingNextChange = false
           return
       }

       // Debounce highlighting
       highlightTimer?.cancel()
       highlightTimer = Just(())
           .delay(for: .seconds(0.3), scheduler: RunLoop.main)
           .sink { [weak textView, weak self] _ in
               // Highlighting happens ONCE after 300ms of no changes
               ...
           }
   }
   ```

4. **For large files, consider disabling highlighting during heavy editing:**
   ```swift
   // If file is >100KB, syntax highlighting is already disabled (current code)
   // For toolbar actions on normal-size files, the debounce is sufficient
   ```

5. **Never re-highlight inside updateUIView():**
   - This is called by SwiftUI on every binding update
   - Calling HighlightingService here creates feedback loop
   - Highlighting should only happen in textViewDidChange debounce timer (already implemented) ✓

**Detection:**
- Toolbar formatting appears briefly, then highlighting re-runs (visual flicker)
- Syntax highlighting seems to "fight" with toolbar (formatting disappears then reappears)
- Selection resets to position 0 after toolbar action
- Large files become unresponsive when toolbar is used

**Risk if missed:** HIGH — toolbar becomes visually broken

---

## Moderate Pitfalls (Major Rework)

### Pitfall 4: NSRange Off-by-One Errors with Emoji and Multi-Byte Characters

**What goes wrong:**
Text contains emoji or zero-width joiners (family emoji 👨‍👩‍👧, skin-tone modifiers 👩🏾, flag combinations 🏳️‍🌈, etc.). Toolbar action calculates NSRange for insertion, but NSRange is based on UTF-16 code units, not Unicode grapheme clusters. Result:

- Single emoji 👨‍👩‍👧 takes 8 UTF-16 units but `Swift.String.count` = 1
- Insertion happens in the middle of the emoji, breaking it visually
- NSRange.location calculation uses `NSString.length` (UTF-16), but developers think in `String.count` (grapheme clusters)
- Selected range includes part of emoji, causing corruption

**Example:**
```
Text: "Hello 👨‍👩‍👧 world"
         0     2              8         (NSString positions, UTF-16 code units)
         0     1              2         (Swift String.count positions, graphemes)

User selects "world" → selectedRange.location = 8 (UTF-16 based)
But if you calculate position using String.count, you get 2
Inserting at position calculated from String.count inserts INSIDE emoji
```

**Why it happens:**
- `UITextView.selectedRange` returns NSRange (UTF-16 based)
- Swift String.count returns grapheme clusters (what you see)
- Confusion between the two leads to position mismatches
- Emoji with modifiers (skin tone, zero-width joiner compositions) have multiple UTF-16 units per visual character

**Consequences:**
- Formatting markers inserted in wrong position (middle of emoji)
- Emoji corrupted and rendered as broken sequences
- If user has Asian text with combining characters, same issue
- Edge case that's hard to reproduce and catch in initial testing
- Real device testing reveals bugs simulator doesn't show

**Prevention:**
1. **Always use NSString length for NSRange calculations:**
   ```swift
   let nsString = text as NSString
   let selectedRange = textView.selectedRange

   // Use NSString throughout, NOT Swift String
   let beforeSelection = nsString.substring(to: selectedRange.location)
   let selectedText = nsString.substring(with: selectedRange)
   let afterSelection = nsString.substring(from: selectedRange.location + selectedRange.length)

   let wrapped = beforeSelection + "**" + selectedText + "**" + afterSelection
   ```

2. **Convert properly if you need Swift String:**
   ```swift
   // When converting NSRange → Swift String range:
   // Use NSString's rangeOfComposedCharacterSequences
   let range = NSRange(location: 10, length: 1)
   let composedRange = nsString.rangeOfComposedCharacterSequences(for: range)
   // This correctly handles multi-unit emoji
   ```

3. **Test extensively with emoji:**
   ```swift
   // Unit test with these:
   // 👨‍👩‍👧 (family emoji with ZWJ, 8 UTF-16 units)
   // 🏳️‍🌈 (flag with ZWJ, multiple units)
   // 👩🏾‍💼 (woman+skin-tone+career, multiple units)
   // ☝🏽 (emoji with skin tone modifier)

   // Verify insertion doesn't break the emoji
   // Verify cursor position after insertion is sensible
   ```

4. **If you must convert NSRange to Swift String index:**
   ```swift
   extension String {
       func index(from: NSRange) -> Index? {
           let nsString = self as NSString
           let start = index(startIndex, offsetBy: from.location)
           return start
       }
   }
   ```

**Detection:**
- User inserts text near emoji, emoji breaks into separate pieces
- Toolbar formatting applied and result looks garbled
- Works fine with ASCII, breaks with emoji/CJK text
- Rare enough to miss in initial testing
- Real device testing reveals it (emoji handling may differ from simulator)

**Risk if missed:** MEDIUM — edge case but critical when it occurs

---

### Pitfall 5: `textViewDidChange` Called Multiple Times Per Keystroke (iOS 17 Specific)

**What goes wrong:**
Toolbar action inserts text via `textView.insertText()` or similar. This triggers `textViewDidChange` delegate callback, which updates the text binding. The binding update may propagate to `updateUIView()`, which may call `HighlightingService.applyMarkdownColors()`, which reassigns `attributedText`, which could trigger `textViewDidChange` AGAIN. On iOS 17 with certain input methods (Cangjie, Sucheng, Stroke), the system itself calls delegate methods twice per keystroke. Result: feedback loop where toolbar actions trigger 2-3+ delegate callbacks, causing:

- Highlighting runs multiple times for single keystroke
- Undo stack grows with multiple entries for single action
- Performance degradation (especially noticeable on large files)
- Inconsistent state if callbacks are not idempotent

**Why it happens:**
- UITextView delegate callback chains are not guaranteed to be single-fire
- iOS 17 CJK input methods call delegate twice per keystroke (known iOS 17 issue)
- Binding update → `updateUIView()` → `attributedText` assignment → potentially triggers `textViewDidChange` again
- No built-in deduplication in UITextView

**Consequences:**
- Large files become sluggish after toolbar actions
- Undo/Redo shows multiple steps for single action
- User sees cursor jump or text flash as highlighting re-runs
- Highlighting state may desync if second callback arrives before first completes

**Prevention:**
1. **Debounce highlighting in textViewDidChange (already done, but verify):**
   ```swift
   // Current code in MarkdownTextEditor.Coordinator:
   func textViewDidChange(_ textView: UITextView) {
       text = textView.text

       guard isHighlightingEnabled else { return }

       // Cancel previous timer and restart
       highlightTimer?.cancel()
       highlightTimer = Just(())
           .delay(for: .seconds(0.3), scheduler: RunLoop.main)
           .sink { [weak textView, weak self] _ in
               // Highlighting happens ONCE after 300ms of no changes
               let selectedRange = textView.selectedRange
               textView.attributedText = HighlightingService.applyMarkdownColors(
                   to: self.text, baseFont: self.font
               )
               textView.selectedRange = selectedRange
           }
   }
   ```
   This is **already implemented**. ✓

2. **For toolbar actions, prevent immediate re-highlighting:**
   ```swift
   // Option A: Cancel pending highlighting on toolbar action
   func boldButtonTapped() {
       highlightTimer?.cancel()  // Cancel pending highlight
       insertBoldFormatting()
       // Let normal debounce timer restart after user stops typing
   }

   // Option B: Set a flag that skips highlighting for this particular change
   @State private var skipNextHighlight = false

   func insertFormattingToolbarText() {
       skipNextHighlight = true
       textView.insertText("**")
       // textViewDidChange fires, but skips highlighting
       // Highlighting resumes after next user keystroke
   }

   // Option C: Batch toolbar actions into single undo group
   // (ensures only one textViewDidChange fired)
   undoManager?.beginUndoGrouping()
   insertText("**"); insertText("text"); insertText("**")
   undoManager?.endUndoGrouping()
   ```

3. **Guard against duplicate delegate calls (optional, adds complexity):**
   ```swift
   private var lastChangeTime: Date?
   private var lastChangeText: String?

   func textViewDidChange(_ textView: UITextView) {
       let now = Date()
       let timeSinceLastChange = now.timeIntervalSince(lastChangeTime ?? .distantPast)

       // Skip if called within 10ms with identical text
       // This catches iOS 17 duplicate calls
       if timeSinceLastChange < 0.01 && textView.text == lastChangeText {
           return  // Likely a duplicate iOS 17 call
       }

       lastChangeTime = now
       lastChangeText = textView.text

       text = textView.text
       // ... rest of implementation
   }
   ```

4. **On iOS 17, consider logging for debugging:**
   ```swift
   if #available(iOS 17, *) {
       // Log CJK input method calls for debugging
       // But don't change behavior—debouncing handles it
   }
   ```

**Detection:**
- Highlighting runs 2-3 times per keystroke (visible via logging)
- Undo stack shows multiple entries for single toolbar action
- Large file (>50KB) becomes laggy during editing
- Profile in Instruments shows multiple calls to `applyMarkdownColors()`
- On iOS 17 with Cangjie/Sucheng/Stroke keyboard, behavior worse

**Risk if missed:** MEDIUM — performance degradation, not data loss

---

### Pitfall 6: Incorrect Line Range Calculation for Bullet/Table Insertion

**What goes wrong:**
Toolbar action "Insert bullet at line" needs to find the current line boundaries. Developer uses `String.split(separator: "\n")` or simple index math, but gets off-by-one in line detection. Result:

- Bullet inserted in wrong line (off by 1)
- Multi-line selection doesn't find all selected lines (first or last line missed)
- Newline handling inconsistent (CRLF vs LF, or missing final newline)
- For table insertion: table inserted at wrong position

**Example:**
```swift
let text = "Line 1\nLine 2\nLine 3"
let selectedRange = NSRange(location: 10, length: 0)  // Position on Line 2

// ❌ BAD: Find line by splitting, doesn't account for NSRange position
let lines = text.split(separator: "\n")  // ["Line 1", "Line 2", "Line 3"]
lines[0] = "- " + lines[0]  // But we're on line 2, not line 0!

// ✓ GOOD: Use NSString to find line boundaries from NSRange position
let nsString = text as NSString
let lineRange = nsString.lineRange(for: selectedRange)
let currentLine = nsString.substring(with: lineRange)
// Insert "- " at lineRange.location
```

**Why it happens:**
- NSRange position (NSString-based) doesn't map 1:1 to String.split results
- Off-by-one when counting newlines
- Newline character handling (CRLF on some systems, LF on others)
- Cursor at end of line vs beginning of next line ambiguity
- Multi-line selection: "which lines are included?" is ambiguous if not careful

**Consequences:**
- Bullets inserted on wrong line
- Tables inserted at wrong position
- Multi-line formatting (e.g., "wrap selection in bullets") only affects wrong lines
- Visually corrupts document
- For tables: table inserted mid-line, breaking content

**Prevention:**
1. **Use NSString.lineRange(for:) to find boundaries:**
   ```swift
   func insertBulletAtCurrentLine() {
       let nsString = textView.text as NSString
       let selectedRange = textView.selectedRange

       // Find the line containing the cursor
       let lineRange = nsString.lineRange(for: selectedRange)
       let lineText = nsString.substring(with: lineRange)

       // Insert "- " at line start
       let bulletedLine = "- " + lineText

       // Replace original line with bulleted version
       textView.undoManager?.beginUndoGrouping()
       nsString.replaceCharacters(in: lineRange, with: bulletedLine)
       textView.undoManager?.endUndoGrouping()
   }
   ```

2. **Handle multi-line selection:**
   ```swift
   func insertBulletsForSelection() {
       let selectedRange = textView.selectedRange
       let nsString = textView.text as NSString

       // Find first and last lines
       let firstLineRange = nsString.lineRange(
           for: NSRange(location: selectedRange.location, length: 0)
       )
       let lastLineRange = nsString.lineRange(
           for: NSRange(location: selectedRange.location + selectedRange.length - 1, length: 0)
       )

       // Expand range to cover all lines
       let fullRange = NSRange(
           location: firstLineRange.location,
           length: (lastLineRange.location + lastLineRange.length) - firstLineRange.location
       )

       // Process all lines in range
       let text = nsString.substring(with: fullRange)
       let bulleted = text.split(separator: "\n").map { "- " + $0 }.joined(separator: "\n")

       textView.undoManager?.beginUndoGrouping()
       nsString.replaceCharacters(in: fullRange, with: bulleted)
       textView.undoManager?.endUndoGrouping()
   }
   ```

3. **Preserve newline style (LF vs CRLF):**
   ```swift
   let hasCarriageReturns = text.contains("\r\n")
   let lineEnding = hasCarriageReturns ? "\r\n" : "\n"

   let lines = text.components(separatedBy: lineEnding)
   let reformatted = lines.map { "- " + $0 }.joined(separator: lineEnding)
   ```

**Detection:**
- Bullet appears on wrong line (off by 1)
- Multi-line selection only affects one line
- First or last line in selection is missed
- Text looks corrupted after bullet/table insertion

**Risk if missed:** MEDIUM — affects advanced toolbar features (bullets, tables)

---

## Minor Pitfalls (Workarounds Sufficient)

### Pitfall 7: Selection Type Confusion (`selectedTextRange` vs `selectedRange`)

**What goes wrong:**
UITextView has two properties for selection:
- `selectedRange` (NSRange, old UIKit, still widely used)
- `selectedTextRange` (UITextRange, new TextKit 2, preferred in iOS 16+)

Developer uses `selectedTextRange` for insertion logic, but other parts of code use `selectedRange`. Mixing the two causes confusion. Result: text inserted at wrong position or not at all. Works on iOS 15, breaks on iOS 16+.

**Why it happens:**
iOS 16+ uses TextKit 2 by default, which prefers `selectedTextRange`. But many UITextView APIs still use NSRange (like the `replace()` method signature). Mixing the two leads to position mismatches.

**Consequences:**
- Text inserted at position 0 instead of current selection
- Cursor position wrong after insertion
- Works on iOS 15, breaks on iOS 16+
- Selection restored incorrectly

**Prevention:**
1. **Consistently use selectedRange for NSRange-based operations:**
   ```swift
   // ✓ GOOD: Consistent use of NSRange
   let range = textView.selectedRange
   let nsString = textView.text as NSString
   let replacement = "**" + nsString.substring(with: range) + "**"
   // Then use replace or insertText with NSRange
   ```

2. **If using TextKit 2 APIs, convert properly:**
   ```swift
   if let selectedTextRange = textView.selectedTextRange {
       // Convert to NSRange
       let start = textView.offset(from: textView.beginningOfDocument, to: selectedTextRange.start)
       let end = textView.offset(from: textView.beginningOfDocument, to: selectedTextRange.end)
       let nsRange = NSRange(location: start, length: end - start)
       // Use nsRange
   }
   ```

3. **Pick one and stick with it for entire toolbar implementation:**
   - Recommendation: use `selectedRange` (NSRange) throughout
   - This is what UITextView APIs expect for simple operations

4. **Test on both iOS 15 and iOS 16+:**
   - TextKit 1 vs TextKit 2 behave differently
   - Simulator or real device on both versions

**Detection:**
- Text inserted at cursor position 0 consistently
- Works in some cases, breaks in others
- Device/iOS version dependent behavior

**Risk if missed:** LOW — workaround is straightforward

---

### Pitfall 8: UIDocument.hasUnsavedChanges Not Updated Immediately

**What goes wrong:**
Toolbar action inserts text. Developer expects `UIDocument.hasUnsavedChanges` to become true immediately (and unsaved indicator `*` to show in title). Instead, it remains false until `scheduleSave()` runs or a keystroke completes. Temporary perception of "save succeeded" even though user hasn't actually saved.

**Why it happens:**
In current implementation, `EditorView.scheduleSave()` calls `doc.updateChangeCount(.done)`, which is debounced by 1.5 seconds. Toolbar actions modify text directly but don't trigger `scheduleSave()`. Result: text changes but `hasUnsavedChanges` lags by 1.5 seconds.

**Consequences:**
- Unsaved indicator doesn't appear after toolbar action
- User thinks changes were saved
- If app crashes immediately after toolbar action, changes are lost
- UX confusion (why is the title not marked with `*`?)

**Prevention:**
1. **Trigger updateChangeCount immediately after toolbar action:**
   ```swift
   func insertBulletAtLine() {
       // ... perform insertion ...

       // Mark document as changed immediately
       document.updateChangeCount(.done)

       // Separately, schedule debounced save
       scheduleSave(for: document)
   }
   ```

2. **Or, route toolbar actions through the text binding:**
   ```swift
   // When toolbar action modifies text, do it via the Binding setter
   // which already calls scheduleSave()

   // In EditorView:
   MarkdownTextEditor(
       text: Binding(
           get: { doc.text },
           set: { newValue in
               doc.text = newValue
               scheduleSave(for: doc)  // Called for every change, including toolbar
           }
       )
   )
   ```

3. **Ensure toolbar actions go through text binding, not direct doc mutation:**
   - This ensures updateChangeCount is called consistently

**Detection:**
- After toolbar action, title doesn't show `*` (unsaved indicator)
- Unsaved indicator appears after next keystroke, not after toolbar action
- User does: toolbar action, crash, reopens app, changes gone (lost work)

**Risk if missed:** LOW — minor UX issue, not data loss, but affects user experience

---

### Pitfall 9: FormattingToolbar Doesn't Appear or Hides Unexpectedly

**What goes wrong:**
Toolbar is attached as `inputAccessoryView` to UITextView. In certain situations (keyboard dismissal, app backgrounding, view rotation), the toolbar disappears or doesn't appear at all when keyboard re-appears.

**Why it happens:**
`inputAccessoryView` is tied to keyboard visibility. If keyboard is dismissed programmatically without resetting the accessory view, it doesn't reappear. UITextView's keyboard state and accessory view lifecycle aren't well synchronized. View controller hierarchy changes (e.g., navigation) can also detach the toolbar.

**Consequences:**
- User types, keyboard appears, toolbar is missing
- User has to dismiss and re-open keyboard to see toolbar
- On landscape rotation, toolbar disappears
- Confusing UX
- User can't access formatting buttons

**Prevention:**
1. **Ensure inputAccessoryView is set before keyboard appears:**
   ```swift
   override func viewDidLoad() {
       let toolbarView = FormattingToolbar()
       textView.inputAccessoryView = toolbarView
       textView.reloadInputViews()  // Force refresh
   }
   ```

2. **After dismissing keyboard, restore:**
   ```swift
   func dismissKeyboard() {
       textView.resignFirstResponder()
       textView.inputAccessoryView = formattingToolbar  // Re-set
       textView.becomeFirstResponder()  // Re-open
       textView.reloadInputViews()  // Refresh
   }
   ```

3. **On rotation, re-attach:**
   ```swift
   override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
       super.viewWillTransition(to: size, with: coordinator)

       coordinator.animate(alongsideChanges: { _ in
           self.textView.inputAccessoryView = self.formattingToolbar
           self.textView.reloadInputViews()
       })
   }
   ```

4. **In SwiftUI, use a View model to ensure toolbar persists:**
   - Keep toolbar reference in @ObservedObject
   - Don't recreate toolbar on every view update

**Detection:**
- Toolbar missing after keyboard dismissal/reappearance
- Toolbar missing on landscape rotation
- Works initially, breaks after certain actions
- User has to close and reopen keyboard to see toolbar

**Risk if missed:** LOW — mostly UX friction, not data loss

---

## Phase-Specific Warnings

| Phase/Topic | Likely Pitfall | Severity | Mitigation Timing |
|-------------|---------------|----------|-------------------|
| **Toolbar UI layout** | Toolbar buttons not fully visible on narrow devices | LOW | Test on iPhone SE before phase completion |
| **Bold/Italic formatting** | Undo stack corruption if using direct textStorage | **CRITICAL** | Implement proper UITextInput usage; test undo/redo extensively |
| **Text insertion position** | Cursor jumps to end or selection is lost | **CRITICAL** | Comprehensive testing with mixed content (ASCII + emoji + CJK) |
| **Bullet/table insertion** | Off-by-one errors in line detection | HIGH | Unit tests for multi-line selection and newline handling |
| **Syntax highlighting conflict** | Highlighting interferes with toolbar formatting | HIGH | Verify selection preservation and debouncing before phase close |
| **Large file performance** | Re-highlighting on every toolbar action slows editor | MEDIUM | Profile with >100KB file; verify debounce works |
| **Undo/Redo UX** | Multiple undo steps for single toolbar action | MEDIUM | Monitor undoManager stack in tests; use beginUndoGrouping |
| **Edge case: emoji** | Formatting breaks with emoji text | MEDIUM | Add unit tests with 👨‍👩‍👧, 🏳️‍🌈, skin-tone modifiers |
| **Auto-save conflict** | Unsaved indicator lags or doesn't show | LOW | Verify updateChangeCount called immediately after toolbar action |
| **Toolbar visibility** | Toolbar disappears after keyboard close/rotation | LOW | Test on landscape, keyboard dismissal scenarios |

---

## Integration Points (Highest Risk)

### 1. UITextView Coordinator + HighlightingService

**Current state:** Highlighting is debounced (300ms). Selection is preserved.

**Risk:** Highlighting re-run during toolbar action clears attributes set by toolbar.

**Check before implementation:**
- Is highlighting debounced? ✓ (300ms delay in current implementation)
- Is selection preserved during re-highlighting? ✓ (current code saves/restores)
- Can toolbar actions skip highlighting on demand? (Not yet implemented — may need addition)
- Does toolbar action restore selection correctly? (Test before closing phase)

### 2. EditorView.scheduleSave + Toolbar Actions

**Current state:** Toolbar actions don't explicitly call scheduleSave.

**Risk:** Toolbar action doesn't trigger unsaved indicator immediately.

**Check before implementation:**
- Does toolbar action call doc.updateChangeCount(.done)? (Likely needs implementation)
- Is scheduleSave triggered by toolbar actions? (Likely needs implementation)
- Does unsaved indicator appear immediately? (Test with all toolbar buttons)

### 3. MarkdownDocument + UIDocument.undoManager

**Current state:** UIDocument's undoManager is available but not explicitly used in current code.

**Risk:** UIDocument undo manager stack becomes inconsistent if toolbar bypasses proper update protocol.

**Check before implementation:**
- Are all text modifications registered with undoManager? (Needs verification/implementation)
- Is `textViewDidChange` the single source of truth for text binding? (Yes, currently)
- Can undoManager handle attribute-only changes? (Needs testing)
- Do undo/redo buttons work with toolbar actions? (Needs implementation + testing)

---

## Recommended Research Flags for Implementation Phase

- [ ] **Test undo/redo with complex scenarios:** Bold on selection, undo, redo, apply italic, verify state
- [ ] **Test emoji insertion:** Verify cursor position and syntax highlighting with 👨‍👩‍👧, 🏳️‍🌈, skin-tone variants
- [ ] **Test large file performance:** Insert formatting in >100KB file, profile highlighting cost
- [ ] **Test multi-line bullet insertion:** Select 3 lines, insert bullets, verify all 3 get bullets
- [ ] **Test iOS 17 edge case:** On iOS 17 simulator with Cangjie keyboard, verify no duplicate highlights
- [ ] **Test on real device:** Emoji handling and cursor position may differ from simulator
- [ ] **Test rotation:** Toolbar should persist across landscape/portrait transitions
- [ ] **Test selection preservation:** Apply formatting, undo, selection should match original
- [ ] **Stress test:** Rapid toolbar clicks; verify state stays consistent

---

## Critical Checklist Before Toolbar Phase Closes

- [ ] All text insertions use UITextInput methods (insert, replace), not direct textStorage
- [ ] Undo grouping used for multi-step operations (bold wrapping = two inserts = one undo)
- [ ] Selection saved before modification, recalculated/restored after
- [ ] Highlighting debounced and doesn't run during rapid toolbar actions
- [ ] NSRange calculated correctly for emoji/CJK text (always use NSString, not String.count)
- [ ] Line boundaries found via NSString.lineRange(), not string split
- [ ] UIDocument.hasUnsavedChanges updated immediately after toolbar action
- [ ] Undo/Redo buttons trigger system undo (backed by UndoManager)
- [ ] No textViewDidChange feedback loops from toolbar actions
- [ ] Toolbar appears/disappears correctly with keyboard
- [ ] Large files (>100KB) don't lag when toolbar is used
- [ ] Emoji text doesn't break when formatting applied
- [ ] Multi-line selection formatting works (all lines get bullet, not just first)
- [ ] Selection restored correctly after formatting applied

---

## Sources

- [UITextView Documentation - Apple Developer](https://developer.apple.com/documentation/uikit/uitextview)
- [UndoManager Documentation - Apple Developer](https://developer.apple.com/documentation/foundation/undomanager)
- [NSRange Documentation - Apple Developer](https://developer.apple.com/documentation/foundation/nsrange)
- [Apple Developer Forum: "How can I integrate my own text changes into UITextView's undo manager?"](https://developer.apple.com/forums/thread/730221)
- [UITextView selectedRange Property - Apple Developer](https://developer.apple.com/documentation/uikit/uitextview/1618615-selectedrange)
- [iOS 17 UITextView shouldChangeText Issues - Apple Developer Forums](https://developer.apple.com/forums/thread/741038)
- [Preserving Cursor Position During Text Updates - GitHub Gist](https://gist.github.com/benjaminsnorris/710d22ef066ae249156f7f959be7debe)
- [Emoji Character Counting and NSRange - Medium](https://dreamcooder.medium.com/how-to-restrict-emoji-input-and-enforce-character-length-in-swift-with-uitextfield-uitextview-0f584dfa2388)
- [TextKit and Text Views - WWDC22 Apple Developer Video](https://developer.apple.com/videos/play/wwdc2022/10090/)
- [textViewDidChange Multiple Calls - Apple Developer Forums](https://discussions.apple.com/thread/649121)

---

*Last updated: 2026-03-26*
