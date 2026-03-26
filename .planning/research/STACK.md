# Technology Stack

**Project:** iOS Markdown Editor (v1.0 validated + v1.1 Formatting Toolbar additions)
**Researched:** 2026-03-26 (toolbar feature research update)
**Scope:** Core stack validated in Phase 1-3 + NEW toolbar feature additions only
**Confidence:** MEDIUM-HIGH (existing stack validated; toolbar feature uses stable iOS APIs)

---

## Recommended Stack

### Core Framework & UI (Validated, Phase 1-3)

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Swift | 5.10+ | Language | Latest stable version with async/await maturity |
| SwiftUI | iOS 16+ | UI Framework | Modern declarative UI; cleaner state management; integrates with FileProvider |
| Combine | iOS 13+ | Reactive programming | Built-in async patterns for file I/O callbacks |
| UITextView (wrapped in SwiftUI) | Built-in | Raw text editing | Better performance than SwiftUI's TextEditor for larger files; supports attributed strings for formatting |

### Text Editing & File I/O (Validated, Phase 1-3)

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| UIDocument | Built-in | File coordination | iOS standard for read/write back to original location; handles concurrent access |
| UIDocumentPickerViewController | iOS 14+ | File picker | Access files from any location (iCloud, Google Drive via "Open With", local storage) |
| RecentFilesStore (custom implementation) | Project v1 | Recent files persistence | Maintains list of recently opened files with bookmark persistence |
| NSAttributedString + UITextView textStorage | Built-in | Syntax highlighting | Markdown syntax coloring via NSTextStorageDelegate observer |

### Storage & Persistence (Validated, Phase 1-3)

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| FileProvider framework | iOS 11+ | Local caching of files | Enables offline access; handles cache management |
| URLCache | Built-in | File caching | Reduces repeated access costs |

---

## **NEW: Formatting Toolbar Feature (v1.1)**

### Toolbar Presentation (NEW)

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| SwiftUI `.toolbar` modifier | iOS 15+ (project uses iOS 16+) | Display formatting buttons above keyboard | Native SwiftUI API; automatically handles keyboard appearance/dismissal animations. No UIKit interoperability complexity required. Cleaner than inputAccessoryView bridging. |
| `ToolbarItemGroup` | iOS 15+ | Group multiple toolbar buttons | Allows multiple buttons in single toolbar group. Use `placement: .keyboard` for above-keyboard positioning. |

**Why NOT inputAccessoryView:** The project targets iOS 16+, which has full support for SwiftUI's `.toolbar(placement: .keyboard)` API. This is native to SwiftUI, requires no UIKit bridging in the UIViewRepresentable, and automatically manages keyboard appearance animations. UIKit's `inputAccessoryView` is the legacy approach, adding unnecessary complexity via UIKit interoperability.

### Text Manipulation APIs (NEW)

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| `UITextView.selectedRange` | Built-in | Get current text selection | NSRange property identifying character range selected by user. Used to detect selection before applying formatting. |
| `UITextInput.insertText(_:)` | Built-in | Insert text at cursor | Inserts at cursor if no selection; replaces selected text if selection exists. Properly integrates with UndoManager for undo tracking. |
| `UITextInput.replace(_:withText:)` | Built-in | Replace specific text range | More explicit than insertText for programmatic replacements. Triggers UndoManager recording correctly. |
| Swift String operations | Standard | Build formatted text | For constructing `**bold**`, `*italic*`, or `- ` bullet prefixes using standard Swift string methods. |

**Why NOT direct textStorage modification:** Direct modification of `textView.textStorage` bypasses the UITextInput protocol layer and breaks UndoManager integration. Text changes won't be undoable, and the syntax highlighting observer may not fire correctly. Always use UITextInput methods.

### Undo/Redo Management (NEW)

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| `UndoManager` | Built-in | Track and reverse custom formatting actions | UITextView provides automatic undo for direct text changes. Custom formatting operations (wrapping, prefixing) must be manually registered with `registerUndo(withTarget:handler:)` to integrate into the system undo stack. |
| Manual undo registration pattern | UIKit pattern | Wrap custom formatting operations | Must call `undoManager?.registerUndo(withTarget: self)` **before** modifying text. This ensures each formatting operation is atomic and undoable. |

**Critical constraint:** Always register undo BEFORE modifying text. Registering after changes capture the wrong state and produce incorrect undo behavior.

---

## Installation & Setup

### Core Stack (Validated)

```bash
# No external dependencies for phases 1-3
# Uses built-in UIKit + SwiftUI + FileProvider
```

### Toolbar Feature (v1.1)

```swift
// No new package dependencies required
// Uses only built-in iOS 16+ frameworks:
// - SwiftUI (already imported)
// - UIKit (already imported)
// - Foundation (already imported)

// Optional: Add to project only if not already present
import SwiftUI
import UIKit
```

---

## Integration with Existing Architecture

### Current State (Phases 1-3)

The project has:
- SwiftUI view hierarchy with `UIViewRepresentable` wrapping UITextView
- NSAttributedString syntax highlighting via `textStorage` observer
- UIDocument-based file open/save
- RecentFilesStore for file history
- Error handling and large-file warnings

### Toolbar Integration Points (NEW for v1.1)

**1. SwiftUI View Modifier Location**

Add `.toolbar` modifier to the view containing the text editor:

```swift
struct EditorView: View {
    @State private var fileContent: String = ""
    @State private var coordinator: TextEditorCoordinator?

    var body: some View {
        TextEditorView(text: $fileContent)
            .onAppear {
                // Create coordinator reference for toolbar button callbacks
                self.coordinator = TextEditorCoordinator(textView: /* reference */)
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Button("B") { coordinator?.applyBold() }
                    Button("I") { coordinator?.applyItalic() }
                    Button("•") { coordinator?.applyBullet() }
                    Button("=") { coordinator?.insertTable() }
                    Divider()
                    Button(action: { coordinator?.undo() }) {
                        Image(systemName: "arrow.counterclockwise")
                    }
                    Button(action: { coordinator?.redo() }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
    }
}
```

**2. Text Manipulation Methods Inside UIViewRepresentable Coordinator**

The Coordinator already adopts `UITextViewDelegate`. Add formatting methods here:

```swift
class TextEditorCoordinator: NSObject, UITextViewDelegate {
    weak var textView: UITextView?

    func applyBold() {
        guard let textView = textView else { return }
        // Implement: wrap selected text or insert markers at cursor
    }

    func applyItalic() {
        guard let textView = textView else { return }
        // Implement: wrap selected text or insert markers at cursor
    }

    func applyBullet() {
        guard let textView = textView else { return }
        // Implement: prefix current line with "- "
    }

    func insertTable() {
        guard let textView = textView else { return }
        // Implement: insert markdown table template
    }

    func undo() {
        textView?.undoManager?.undo()
    }

    func redo() {
        textView?.undoManager?.redo()
    }
}
```

**3. UndoManager Access**

UITextView's `undoManager` property is directly accessible on the wrapped instance:

```swift
// Register custom undo before modifying text
textView.undoManager?.registerUndo(withTarget: self) { coordinator in
    // Restoration code (reverses the formatting operation)
}

// Apply formatting
textView.replace(textView.selectedTextRange ?? UITextRange(), withText: formattedText)
```

---

## Implementation Patterns

### Pattern 1: Wrapping Selected Text (Bold/Italic)

**Use case:** Bold and italic buttons that wrap selected text or insert markers at cursor.

```swift
func applyBold() {
    guard let textView = self.textView else { return }
    let selectedRange = textView.selectedRange

    // Register undo BEFORE modifying text
    // Capture current state for restoration
    let originalText = (textView.text as NSString).substring(with: selectedRange)
    textView.undoManager?.registerUndo(withTarget: self) { coordinator in
        // Restore original text on undo
        textView.selectedRange = selectedRange
        if let textRange = textView.selectedTextRange {
            textView.replace(textRange, withText: originalText)
        }
    }

    // Apply formatting
    if selectedRange.length > 0 {
        // Text is selected: wrap it with **markers**
        let selectedText = (textView.text as NSString).substring(with: selectedRange)
        let wrapped = "**\(selectedText)**"
        if let textRange = textView.selectedTextRange {
            textView.replace(textRange, withText: wrapped)
        }
    } else {
        // No selection: insert **markers** and position cursor between them
        textView.insertText("****")
        // Move cursor to middle of markers
        textView.selectedRange = NSRange(location: selectedRange.location + 2, length: 0)
    }
}
```

**Key points:**
- Always register undo BEFORE modifying text
- Use `UITextInput.replace(_:withText:)` for programmatic changes (respects undo manager)
- Avoid direct `textStorage` modification (bypasses undo tracking)
- Convert NSRange to UITextRange when calling UITextInput methods

### Pattern 2: Prefixing Current Line (Bullet Points)

**Use case:** Bullet list button that prefixes the current line with `- `.

```swift
func applyBullet() {
    guard let textView = self.textView else { return }
    let currentRange = textView.selectedRange
    let text = textView.text as NSString

    // Find start of current line (search backwards for newline)
    let lineStartRange = text.range(
        of: "\n",
        options: .backwards,
        range: NSRange(location: 0, length: currentRange.location)
    )
    let lineStart = lineStartRange.length == 0 ? 0 : lineStartRange.location + 1

    // Capture state for undo
    let originalLinePrefix = text.substring(with: NSRange(location: lineStart, length: 2))
    let wasAlreadyBullet = originalLinePrefix == "- "

    // Register undo
    textView.undoManager?.registerUndo(withTarget: self) { coordinator in
        textView.selectedRange = NSRange(location: lineStart, length: 0)
        if wasAlreadyBullet {
            // Remove bullet marker
            if let range = textView.selectedTextRange {
                textView.replace(range, withText: "")
            }
        } else {
            // Restore original content (more complex for full undo)
        }
    }

    // Apply bullet marker
    textView.selectedRange = NSRange(location: lineStart, length: 0)
    textView.insertText("- ")
}
```

**Key points:**
- UITextView doesn't have direct line-access APIs; use NSString range methods to find line boundaries
- Each formatting operation should be a single undo entry
- Handle edge cases (already has bullet, first line, etc.)

### Pattern 3: Undo and Redo Button Actions

**Use case:** Undo/Redo buttons in toolbar that trigger system undo/redo.

```swift
func undo() {
    textView?.undoManager?.undo()
}

func redo() {
    textView?.undoManager?.redo()
}

// For button state management:
var canUndo: Bool {
    textView?.undoManager?.canUndo ?? false
}

var canRedo: Bool {
    textView?.undoManager?.canRedo ?? false
}

// In toolbar:
Button(action: undo) {
    Image(systemName: "arrow.counterclockwise")
}
.disabled(!canUndo)
```

**Key points:**
- Button should be disabled when `undoManager?.canUndo == false`
- No custom registration needed; system handles undo for all text changes made via UITextInput
- Use `@Published` or state binding to update button disabled state when undo stack changes

### Pattern 4: Table Insertion

**Use case:** Table button that inserts a markdown table template at cursor.

```swift
func insertTable() {
    guard let textView = self.textView else { return }

    let tableTemplate = """
    | Column 1 | Column 2 | Column 3 |
    |----------|----------|----------|
    | Data 1   | Data 2   | Data 3   |
    """

    let insertionPoint = textView.selectedRange.location

    // Register undo
    textView.undoManager?.registerUndo(withTarget: self) { coordinator in
        // Delete inserted table on undo
        let tableLength = tableTemplate.count
        textView.selectedRange = NSRange(location: insertionPoint, length: tableLength)
        if let textRange = textView.selectedTextRange {
            textView.replace(textRange, withText: "")
        }
    }

    // Insert table
    textView.insertText(tableTemplate)

    // Optionally reposition cursor to first data cell
    // (or to end of table for continued editing)
}
```

**Key points:**
- Multi-line content can be inserted directly with `insertText`
- Consider repositioning cursor after insertion for UX (e.g., first table cell)
- Table template is plain text; no special handling needed

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: Direct textStorage Modification

**What:** Modifying `textView.textStorage` directly for formatting.

**Why bad:**
- Bypasses the UITextInput protocol layer
- Circumvents UndoManager recording
- Text changes won't integrate with undo/redo
- Syntax highlighting observer may not fire correctly

**Instead:**
```swift
// WRONG
textView.textStorage.replaceCharacters(in: range, with: "**text**")

// RIGHT
textView.replace(textView.selectedTextRange ?? UITextRange(), withText: "**text**")
```

### Anti-Pattern 2: Registering Undo After Text Change

**What:** Modifying text first, then registering undo afterward.

**Why bad:** UndoManager captures the state AFTER the change, producing incorrect undo behavior.

**Instead:**
```swift
// WRONG
textView.replace(range, withText: newText)
textView.undoManager?.registerUndo(withTarget: self) { ... } // Too late!

// RIGHT
textView.undoManager?.registerUndo(withTarget: self) { ... } // Register first
textView.replace(range, withText: newText)                   // Then apply
```

### Anti-Pattern 3: Confusing selectedRange vs selectedTextRange

**What:** Mixing `selectedRange` (NSRange) with `selectedTextRange` (UITextRange).

**Why bad:** Different APIs expect different types. UITextRange is opaque; NSRange is concrete with location/length.

**Instead:**
```swift
// WRONG
let range: UITextRange = textView.selectedRange  // Type mismatch

// RIGHT
let nsRange: NSRange = textView.selectedRange                         // For calculations
let uiRange: UITextRange? = textView.selectedTextRange                // For UITextInput APIs
textView.replace(uiRange ?? UITextRange(), withText: "text")
```

### Anti-Pattern 4: Complex Undo Chains

**What:** Registering multiple undo operations for a single user action.

**Why bad:** Creates confusing undo history; user expects one undo per button tap.

**Instead:**
```swift
// WRONG
for char in characters {
    textView.undoManager?.registerUndo(withTarget: self) { ... }
}

// RIGHT: Group into single undo entry
textView.undoManager?.beginUndoGrouping()
for step in steps {
    // Perform operations
}
textView.undoManager?.endUndoGrouping()

// OR: Single registration for atomic operation
textView.undoManager?.registerUndo(withTarget: self) { _ in
    // Restore entire state
}
```

### Anti-Pattern 5: UIKit inputAccessoryView Bridge

**What:** Wrapping inputAccessoryView in UIViewRepresentable for iOS 16+.

**Why bad:** Unnecessary complexity. SwiftUI's `.toolbar(placement: .keyboard)` is simpler, native, and requires no UIKit bridging.

**Instead:**
```swift
// WRONG (for iOS 16+ projects)
struct TextViewWithAccessory: UIViewRepresentable {
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        let toolbar = UIToolbar()
        textView.inputAccessoryView = toolbar  // Bridging complexity
        return textView
    }
}

// RIGHT (iOS 15+ projects like this one)
TextEditorView(text: $content)
    .toolbar {
        ToolbarItemGroup(placement: .keyboard) {
            Button("Bold") { applyBold() }
        }
    }
```

---

## Feasibility Assessment

| Concern | Status | Confidence | Notes |
|---------|--------|------------|-------|
| Keyboard toolbar integration | ✓ Feasible | HIGH | SwiftUI `.toolbar` is built-in; no external dependencies. Works seamlessly with existing UIViewRepresentable. iOS 16+ fully supports this. |
| Text selection wrapping | ✓ Feasible | HIGH | UITextView `selectedRange` and UITextInput methods are stable APIs. Wrapping logic is straightforward string manipulation. |
| Undo/redo registration | ✓ Feasible | MEDIUM | Requires careful ordering (register before modifying). Works reliably once pattern is established. Easy to miss subtle bugs if not careful. |
| Syntax highlighting preservation | ✓ Feasible | HIGH | Existing NSAttributedString system handles this. Using UITextInput methods ensures highlighting observer fires correctly. |
| No new dependencies | ✓ Feasible | HIGH | Everything is in iOS 16+ standard libraries. No pods, no external packages needed. |
| Integration with existing editor | ✓ Feasible | HIGH | Toolbar buttons call Coordinator methods; Coordinator already manages UITextView. Minimal changes to existing architecture. |

---

## Comparison: Toolbar Approaches (iOS 16+)

| Aspect | SwiftUI `.toolbar` (RECOMMENDED) | UIKit inputAccessoryView |
|--------|----------------------------------|------------------------|
| **API Location** | SwiftUI view modifier | UITextView property |
| **Keyboard animation** | Automatic | Manual handling |
| **Complexity** | Minimal; pure SwiftUI | Medium; UIKit bridging |
| **UIViewRepresentable integration** | Cleaner; modifier applied outside | More complex; bridge inside |
| **iOS version** | 15+ (project uses 16+) | Any iOS version |
| **Maintenance burden** | Lower | Higher |
| **Recommendation for this project** | ✓ USE THIS | Use only if iOS <15 required |

---

## Version Compatibility

- **Minimum iOS:** iOS 16.0 (project requirement)
- **SwiftUI `.toolbar` support:** iOS 15+ ✓
- **UITextView APIs:** All iOS versions ✓
- **UndoManager:** All iOS versions ✓
- **Swift:** 5.10+
- **Xcode:** 15.1+

---

## Confidence Assessment

| Area | Level | Reason |
|------|-------|--------|
| **SwiftUI `.toolbar` API** | HIGH | Stable since iOS 15; well-documented; widely used in modern iOS development |
| **UITextView text manipulation** | HIGH | UITextInput protocol is stable; no breaking changes; documented in official Apple docs |
| **UndoManager integration** | MEDIUM | API is stable, but requires careful implementation (order of operations). Easy to introduce bugs. |
| **No new dependencies** | HIGH | All APIs are built-in to iOS 16+ |
| **Existing architecture compatibility** | HIGH | Toolbar integrates cleanly with UIViewRepresentable + Coordinator pattern |

---

## Deferred Decisions (Phase 2+)

For future toolbar enhancements:

1. **Rich text formatting** (Phase 2+)
   - When: If markdown syntax alone becomes insufficient
   - Candidate: Custom NSAttributedString builder or third-party rich text library

2. **Markdown preview** (Phase 2)
   - Candidate: SwiftMarkdown, cmark-swift, Down
   - When: Phase 2 (preview feature)

3. **Keyboard dismissal on action** (Phase 1.1 or 2)
   - Current: Keyboard stays open after button tap
   - When: If UX research suggests dismissal improves experience
   - How: Call `textView.resignFirstResponder()` after formatting

4. **Custom keyboard toolbar appearance** (Phase 2+)
   - Styling, colors, button sizes
   - When: After MVP validation shows toolbar is useful

---

## Sources

### SwiftUI Keyboard Toolbar

- [How to add a toolbar to the keyboard - Hacking with Swift](https://www.hackingwithswift.com/quick-start/swiftui/how-to-add-a-toolbar-to-the-keyboard)
- [keyboard placement - Apple Developer Documentation](https://developer.apple.com/documentation/swiftui/toolbaritemplacement/keyboard)
- [ToolbarItemGroup - Apple Developer Documentation](https://developer.apple.com/documentation/swiftui/toolbaritemgroup)
- [Managing Keyboard Toolbar Items in SwiftUI (iOS 15+) - BleepingSwift](https://bleepingswift.com/blog/keyboard-toolbar-swiftui)

### UITextView Text Manipulation & Selection

- [selectedRange - Apple Developer Documentation](https://developer.apple.com/documentation/uikit/uitextview/1618615-selectedrange)
- [UITextInput protocol - Apple Developer Documentation](https://developer.apple.com/documentation/uikit/uitextinput)
- [How can I integrate my own text changes into UITextView's undo manager? - Apple Developer Forums](https://developer.apple.com/forums/thread/730221)
- [Using Text Kit to Manage Text in Your iOS Apps - AppCoda](https://www.appcoda.com/intro-text-kit-ios-programming-guide/)

### UndoManager & Custom Operations

- [undoManager - Apple Developer Documentation](https://developer.apple.com/documentation/uikit/uiresponder/1621122-undomanager)
- [UITextView with custom NSUndoManager - Apple Developer Forums](https://developer.apple.com/forums/thread/715693)
- [UndoManager in Swift - Medium](https://medium.com/@hitendrahckr/undomanager-in-swift-5-with-simple-example-8c791e231b87)

### UIViewRepresentable Integration

- [UIViewRepresentable - Apple Developer Documentation](https://developer.apple.com/documentation/swiftui/uiviewrepresentable)
- [Creating a SwiftUI TextView Using UIViewRepresentable - AppCoda](https://www.appcoda.com/swiftui-textview-uiviewrepresentable/)

### Alternatives & Comparisons

- [How to add a toolbar above the keyboard using inputAccessoryView - Hacking with Swift](https://www.hackingwithswift.com/example-code/uikit/how-to-add-a-toolbar-above-the-keyboard-using-inputaccessoryview) (legacy approach, not recommended for iOS 16+)
- [InputAccessoryView with SwiftUI - Apple Developer Forums](https://developer.apple.com/forums/thread/684991)

---

*Last updated: 2026-03-26 — v1.1 Formatting Toolbar feature research complete*
*Previous version (v1.0 core stack): 2026-03-25*
