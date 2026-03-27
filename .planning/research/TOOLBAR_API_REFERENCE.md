# Toolbar Feature: API Reference & Technical Q&A

**Purpose:** Answer the specific technical questions from the research brief
**Researched:** 2026-03-26

---

## Q1: inputAccessoryView Approach vs SwiftUI Overlay

**Question:** What's the best approach for a keyboard-docked formatting toolbar in iOS 16+ with existing UIViewRepresentable?

### Answer: Use SwiftUI `.toolbar(placement: .keyboard)`

#### Why This Approach

**SwiftUI `.toolbar` (RECOMMENDED)**

```swift
TextEditorView(text: $fileContent)
    .toolbar {
        ToolbarItemGroup(placement: .keyboard) {
            Button("B") { applyBold() }
            Button("I") { applyItalic() }
            // ... more buttons
        }
    }
```

**Advantages:**
- ✓ Native SwiftUI API (iOS 15+)
- ✓ Automatic keyboard appearance/dismissal animations
- ✓ No UIKit bridging complexity
- ✓ Cleaner code structure
- ✓ Works seamlessly with UIViewRepresentable below

**Disadvantages:**
- iOS version requirement: 15+ (but project targets 16+, so ✓)

#### Alternative: UIKit inputAccessoryView (Legacy)

```swift
struct TextEditorView: UIViewRepresentable {
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()

        // Create toolbar
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 100, height: 44))
        let boldButton = UIBarButtonItem(title: "B", style: .plain, target: context.coordinator, action: #selector(TextEditorCoordinator.applyBold))
        toolbar.items = [boldButton]

        // Assign to inputAccessoryView
        textView.inputAccessoryView = toolbar

        return textView
    }
}
```

**Advantages:**
- Works on any iOS version
- More explicit toolbar control (UIToolbar properties)

**Disadvantages:**
- ✗ Requires UIKit bridging in UIViewRepresentable
- ✗ Manual animation handling for keyboard
- ✗ More boilerplate code
- ✗ Less idiomatic to SwiftUI

### Recommendation

**Use SwiftUI `.toolbar(placement: .keyboard)`.** It's the modern approach, requires less code, and integrates cleaner with the existing SwiftUI view hierarchy. The UIKit inputAccessoryView approach is only necessary for iOS <15 support, which this project doesn't need.

---

## Q2: UITextView Text Manipulation APIs for Selection-Wrapping

**Question:** What APIs should we use to wrap selected text (bold, italic) or insert text at cursor position?

### Answer: Use `UITextView.selectedRange` + `UITextInput.replace()`

#### The Right APIs

**1. Get the current selection:**

```swift
let selectedRange: NSRange = textView.selectedRange
// NSRange has two properties: location (Int) and length (Int)

// Check if text is selected
if selectedRange.length > 0 {
    // User has selected text
} else {
    // User has cursor at position, no selection
}
```

**2. Insert text at cursor or replace selection:**

```swift
// Option A: insertText (simpler, works for both cases)
textView.insertText("**")  // Inserts at cursor or replaces selection

// Option B: replace (more explicit, recommended)
if let textRange = textView.selectedTextRange {
    textView.replace(textRange, withText: "**")
}
```

**3. Get the actual selected text (if needed):**

```swift
let selectedText = (textView.text as NSString).substring(with: selectedRange)
let wrapped = "**\(selectedText)**"
```

#### Complete Example: Wrap Selected Text (Bold)

```swift
func applyBold() {
    guard let textView = self.textView else { return }
    let selectedRange = textView.selectedRange

    // Register undo FIRST (critical!)
    let originalText = (textView.text as NSString).substring(with: selectedRange)
    textView.undoManager?.registerUndo(withTarget: self) { coordinator in
        textView.selectedRange = selectedRange
        if let textRange = textView.selectedTextRange {
            textView.replace(textRange, withText: originalText)
        }
    }

    // Apply formatting
    if selectedRange.length > 0 {
        // User selected text: wrap it
        let selectedText = (textView.text as NSString).substring(with: selectedRange)
        let wrapped = "**\(selectedText)**"
        if let textRange = textView.selectedTextRange {
            textView.replace(textRange, withText: wrapped)
        }
    } else {
        // No selection: insert markers and position cursor between them
        textView.insertText("****")
        // Move cursor to position between markers
        textView.selectedRange = NSRange(location: selectedRange.location + 2, length: 0)
    }
}
```

#### What NOT to Do

```swift
// ✗ WRONG: Direct textStorage modification
textView.textStorage.replaceCharacters(in: range, with: "**text**")
// Problem: Bypasses UndoManager; undo won't work

// ✗ WRONG: Confusing NSRange with UITextRange
let range: UITextRange = textView.selectedRange  // Type mismatch!

// ✗ WRONG: Forgetting to register undo first
textView.replace(range, withText: newText)
textView.undoManager?.registerUndo(...)  // Too late!
```

#### API Reference Table

| API | Type | Purpose | Returns |
|-----|------|---------|---------|
| `textView.selectedRange` | NSRange | Current selection | NSRange(location: Int, length: Int) |
| `textView.selectedTextRange` | UITextRange? | Current selection (opaque) | UITextRange object |
| `textView.insertText(_:)` | Method | Insert at cursor/replace selection | Void |
| `textView.replace(_:withText:)` | Method | Replace specific range | Void |
| `textView.text` | String | All text in view | String |
| `textView.textStorage` | NSTextStorage | Underlying storage (avoid direct access) | NSTextStorage |

---

## Q3: Undo Registration for Custom Formatting Operations

**Question:** How do we register custom text manipulation (wrapping, prefixing) with the UndoManager?

### Answer: Call `registerUndo(withTarget:handler:)` BEFORE modifying text

#### The Critical Pattern

```swift
// CRITICAL ORDER: Register first, modify second

// Step 1: Register undo (capture current state)
textView.undoManager?.registerUndo(withTarget: self) { coordinator in
    // This closure runs when user taps Undo
    // Restore the original text/state here
}

// Step 2: Apply formatting (modify the text)
textView.replace(range, withText: formattedText)
```

#### Why Order Matters

The UndoManager captures the textView's state at registration time. If you modify text first, it captures the wrong state:

```swift
// ✗ WRONG ORDER
textView.replace(range, withText: "**text**")
textView.undoManager?.registerUndo(withTarget: self) { ... }
// Result: Undo restores to the formatted state, not the original!

// ✓ RIGHT ORDER
textView.undoManager?.registerUndo(withTarget: self) { ... }
textView.replace(range, withText: "**text**")
// Result: Undo correctly restores to original state
```

#### Complete Example: Bold with Proper Undo

```swift
func applyBold() {
    guard let textView = self.textView else { return }
    let selectedRange = textView.selectedRange

    // Capture original state
    let originalText = (textView.text as NSString).substring(with: selectedRange)

    // Step 1: Register undo FIRST
    textView.undoManager?.registerUndo(withTarget: self) { coordinator in
        // Restore original text on undo
        let originalRange = selectedRange
        textView.selectedRange = originalRange

        if let textRange = textView.selectedTextRange {
            textView.replace(textRange, withText: originalText)
        }
    }

    // Step 2: Apply formatting
    if selectedRange.length > 0 {
        // Wrap selected text
        let selectedText = (textView.text as NSString).substring(with: selectedRange)
        let wrapped = "**\(selectedText)**"

        if let textRange = textView.selectedTextRange {
            textView.replace(textRange, withText: wrapped)
        }
    } else {
        // Insert markers at cursor
        textView.insertText("****")
        textView.selectedRange = NSRange(location: selectedRange.location + 2, length: 0)
    }
}
```

#### Other Undo Methods

```swift
// Check if undo is available
if textView.undoManager?.canUndo ?? false {
    // Undo button should be enabled
}

// Trigger undo
textView.undoManager?.undo()

// Trigger redo
textView.undoManager?.redo()

// Group multiple operations into single undo
textView.undoManager?.beginUndoGrouping()
// ... perform multiple operations ...
textView.undoManager?.endUndoGrouping()

// Disable undo tracking temporarily
textView.undoManager?.disableUndoRegistration()
// ... perform operations without undo ...
textView.undoManager?.enableUndoRegistration()
```

#### Common Mistakes

```swift
// ✗ Mistake 1: Forgetting to capture original state
textView.undoManager?.registerUndo(withTarget: self) { _ in
    // What state do we restore to? Forgot to capture it!
}

// ✓ Fix: Capture before registering
let originalText = textView.text
textView.undoManager?.registerUndo(withTarget: self) { _ in
    textView.text = originalText  // Restore to captured state
}

// ✗ Mistake 2: Not converting NSRange to UITextRange
let nsRange = textView.selectedRange
textView.replace(nsRange, withText: "text")  // Type error!

// ✓ Fix: Use selectedTextRange for UITextInput methods
if let uiRange = textView.selectedTextRange {
    textView.replace(uiRange, withText: "text")
}

// ✗ Mistake 3: Complex nested undo operations
for line in lines {
    textView.undoManager?.registerUndo(withTarget: self) { ... }
    // One button = multiple undo entries. Confusing!
}

// ✓ Fix: Group into single undo entry
textView.undoManager?.beginUndoGrouping()
for line in lines {
    // Perform operations
}
textView.undoManager?.endUndoGrouping()
```

#### Undo Registration Reference

| Method | Purpose | When to Use |
|--------|---------|-------------|
| `registerUndo(withTarget:handler:)` | Register single undo action | Most common; each button = one undo entry |
| `beginUndoGrouping()` / `endUndoGrouping()` | Group multiple operations | Complex multi-step actions |
| `disableUndoRegistration()` / `enableUndoRegistration()` | Temporarily pause undo tracking | Batch operations that shouldn't be undoable |
| `removeAllActions()` | Clear entire undo stack | Rarely needed |

---

## Integration with Existing UIViewRepresentable

**Question:** How does the toolbar integrate with the existing UIViewRepresentable architecture?

### Architecture Diagram

```
SwiftUI View (EditorView)
    ├── Modifier: .toolbar(placement: .keyboard) { ... }
    │   └── Button("B") { applyBold() }  // Calls Coordinator method
    │
    └── TextEditorView (UIViewRepresentable)
        ├── makeUIView() → creates UITextView
        ├── makeCoordinator() → creates TextEditorCoordinator
        └── updateUIView() → updates text content

TextEditorCoordinator (NSObject, UITextViewDelegate)
    ├── var textView: UITextView
    ├── func applyBold() { ... }
    ├── func applyItalic() { ... }
    ├── func applyBullet() { ... }
    ├── func insertTable() { ... }
    ├── func undo() { ... }
    ├── func redo() { ... }
    └── // UITextViewDelegate methods
```

### Implementation Pattern

**1. SwiftUI View with Toolbar:**

```swift
struct EditorView: View {
    @State private var fileContent: String = ""
    @State private var textViewCoordinator: TextEditorCoordinator?

    var body: some View {
        VStack {
            TextEditorView(
                text: $fileContent,
                coordinatorCallback: { coordinator in
                    self.textViewCoordinator = coordinator
                }
            )
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Button("B") {
                    textViewCoordinator?.applyBold()
                }
                Button("I") {
                    textViewCoordinator?.applyItalic()
                }
                // ... more buttons
                Button(action: { textViewCoordinator?.undo() }) {
                    Image(systemName: "arrow.counterclockwise")
                }
            }
        }
    }
}
```

**2. UIViewRepresentable with Coordinator Access:**

```swift
struct TextEditorView: UIViewRepresentable {
    @Binding var text: String
    var coordinatorCallback: ((TextEditorCoordinator) -> Void)?

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        context.coordinator.textView = textView
        return textView
    }

    func makeCoordinator() -> TextEditorCoordinator {
        let coordinator = TextEditorCoordinator()
        coordinatorCallback?(coordinator)  // Pass to parent
        return coordinator
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
    }
}
```

**3. Coordinator with Formatting Methods:**

```swift
class TextEditorCoordinator: NSObject, UITextViewDelegate {
    weak var textView: UITextView?

    func applyBold() {
        guard let textView = textView else { return }
        let selectedRange = textView.selectedRange

        // Register undo
        let originalText = (textView.text as NSString).substring(with: selectedRange)
        textView.undoManager?.registerUndo(withTarget: self) { _ in
            textView.selectedRange = selectedRange
            if let range = textView.selectedTextRange {
                textView.replace(range, withText: originalText)
            }
        }

        // Apply formatting
        if selectedRange.length > 0 {
            let selectedText = (textView.text as NSString).substring(with: selectedRange)
            let wrapped = "**\(selectedText)**"
            if let range = textView.selectedTextRange {
                textView.replace(range, withText: wrapped)
            }
        } else {
            textView.insertText("****")
            textView.selectedRange = NSRange(location: selectedRange.location + 2, length: 0)
        }
    }

    func undo() {
        textView?.undoManager?.undo()
    }

    func redo() {
        textView?.undoManager?.redo()
    }

    // Other UITextViewDelegate methods...
}
```

### Key Integration Points

1. **Toolbar buttons live in SwiftUI** (clean, idiomatic)
2. **Formatting logic lives in Coordinator** (respects existing architecture)
3. **Coordinator has direct access to UITextView** (can call registerUndo, selectedRange, etc.)
4. **No changes to makeUIView/updateUIView** (backward compatible)
5. **Syntax highlighting observer continues working** (UITextInput methods preserve textStorage callbacks)

---

## Summary Table

| Question | Answer | Why |
|----------|--------|-----|
| **Toolbar approach?** | SwiftUI `.toolbar(placement: .keyboard)` | iOS 16+ support, simpler, native |
| **Selection API?** | `textView.selectedRange` (NSRange) | Standard property, simple interface |
| **Text modification?** | `textView.replace(_:withText:)` | Respects UndoManager, standard practice |
| **Undo registration?** | `registerUndo(withTarget:handler:)` before text change | Captures correct state for restoration |
| **Integration point?** | Add methods to existing Coordinator | Minimal changes, respects architecture |

---

## Sources

- [UITextView.selectedRange - Apple Developer Documentation](https://developer.apple.com/documentation/uikit/uitextview/1618615-selectedrange)
- [UITextInput - Apple Developer Documentation](https://developer.apple.com/documentation/uikit/uitextinput)
- [UndoManager - Apple Developer Documentation](https://developer.apple.com/documentation/uikit/uiresponder/1621122-undomanager)
- [SwiftUI toolbar - Apple Developer Documentation](https://developer.apple.com/documentation/swiftui/view/toolbar(content:))
- [How can I integrate my own text changes into UITextView's undo manager? - Apple Developer Forums](https://developer.apple.com/forums/thread/730221)

---

*Last updated: 2026-03-26*
