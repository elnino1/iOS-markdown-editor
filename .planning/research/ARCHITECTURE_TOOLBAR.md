# Architecture: Formatting Toolbar Integration

**Domain:** iOS markdown editor (v1.1 toolbar integration)
**Researched:** 2026-03-26
**Confidence:** HIGH (Apple WWDC23 guidance + UIKit patterns established)

---

## Standard Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                       SwiftUI Presentation Layer                     │
├─────────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────────────┐  ┌─────────────────┐   │
│  │  EditorView  │  │  FormattingToolbar   │  │  Navigation UI  │   │
│  │   (SwiftUI)  │  │     (SwiftUI)        │  │   (SwiftUI)     │   │
│  └──────┬───────┘  └──────┬───────────────┘  └─────────────────┘   │
│         │                 │ (onFormat closure)                      │
├─────────┴─────────────────┴─────────────────────────────────────────┤
│                   UIKit/UIViewRepresentable Layer                    │
├─────────────────────────────────────────────────────────────────────┤
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │          MarkdownTextEditor (UIViewRepresentable)              │ │
│  │  ┌──────────────────┐  ┌──────────────────────────────────┐   │ │
│  │  │   UITextView     │  │ Coordinator (UITextViewDelegate) │   │ │
│  │  │                  │  │ - handles formatting commands    │   │ │
│  │  │  inputAccessory  │◄─┤ - maintains text binding        │   │ │
│  │  │  View (toolbar)  │  │ - triggers highlighting         │   │ │
│  │  └──────────────────┘  └──────────────────────────────────┘   │ │
│  └────────────────────────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────────────────────────┤
│                      Business Logic Layer                            │
├─────────────────────────────────────────────────────────────────────┤
│  ┌──────────────────┐  ┌──────────────────┐  ┌────────────────┐   │
│  │ FormattingService│  │ HighlightingServ │  │ RecentFilesStr │   │
│  │ (text mutation)  │  │ (syntax colors)  │  │ (file history) │   │
│  └──────────────────┘  └──────────────────┘  └────────────────┘   │
├─────────────────────────────────────────────────────────────────────┤
│                         Model/State Layer                            │
├─────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌──────────────────────────────────────┐    │
│  │    AppState     │  │  MarkdownDocument (UIDocument)      │    │
│  │ (@MainActor)    │  │  - File I/O, UIDocument lifecycle  │    │
│  │ - Document mgmt │  │  - Auto-save coordination           │    │
│  └─────────────────┘  └──────────────────────────────────────┘    │
├─────────────────────────────────────────────────────────────────────┤
│                      Persistence Layer                               │
├─────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  File System (security-scoped URLs, UIDocument framework)   │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Implementation |
|-----------|-----------------|-----------------|
| **FormattingToolbar** | Render button row, emit formatting commands | SwiftUI View, static layout, closure callbacks |
| **Coordinator** | Handle formatting commands, maintain UITextView delegate, sync bindings | NSObject + UITextViewDelegate, command dispatcher |
| **MarkdownTextEditor** | Create UITextView, attach toolbar as inputAccessoryView, manage lifecycle | UIViewRepresentable wrapper |
| **FormattingService** | Execute text mutations (wrap, prefix, insert), leverage undoManager | Static struct with pure functions |
| **EditorView** | SwiftUI editor screen, auto-save scheduling, unsaved state UI | SwiftUI View, integrates MarkdownTextEditor |
| **AppState** | Document lifecycle, file I/O coordination, screen state | @MainActor ObservableObject |
| **MarkdownDocument** | File read/write, encoding handling, change tracking | UIDocument subclass |
| **HighlightingService** | Apply markdown syntax colors (unchanged) | Static struct, regex-based coloring |

---

## Recommended Project Structure

```
MarkdownEditor/
├── Core Views
│   ├── EditorView.swift                 # Editor screen (existing)
│   ├── HomeView.swift                   # File picker, recent files (existing)
│   ├── MarkdownTextEditor.swift         # UIViewRepresentable wrapper (MODIFIED)
│   ├── FormattingToolbar.swift          # Toolbar UI (NEW)
│   └── ContentView.swift                # Root navigation (existing)
│
├── View Models & State
│   ├── AppState.swift                   # Document/file state (existing, unchanged)
│   └── MarkdownDocument.swift           # UIDocument subclass (existing, unchanged)
│
├── Services
│   ├── HighlightingService.swift        # Syntax coloring (existing, unchanged)
│   ├── FormattingService.swift          # Text mutations (NEW)
│   └── RecentFilesStore.swift           # Recent files tracking (existing)
│
├── Theme
│   └── ThemeColors.swift                # Color definitions (existing)
│
└── App
    └── MarkdownEditorApp.swift          # @main entry (existing)
```

### Structure Rationale

- **Core Views:** UI layer separates presentation concerns. FormattingToolbar is SwiftUI-only; MarkdownTextEditor bridges UIKit and SwiftUI.
- **View Models & State:** App-level state (AppState) and document model (MarkdownDocument) remain unchanged; toolbar integration doesn't touch file I/O.
- **Services:** Pure business logic separated from UI. FormattingService handles text mutations independently; HighlightingService applies colors after. No circular dependencies.
- **Theme:** Color definitions remain isolated; toolbar uses existing ThemeColors if needed.
- **App:** Single entry point, unchanged.

---

## Architectural Patterns

### Pattern 1: UITextView-Docked Toolbar via inputAccessoryView

**What:** FormattingToolbar (SwiftUI) is wrapped in UIHostingController and attached to UITextView's inputAccessoryView property. iOS automatically positions it above the keyboard.

**When to use:**
- Need toolbar to dock with iOS keyboard
- Keyboard can be dismissed, undocked (iPad), or floating—all handled by iOS
- Want native iOS behavior without custom keyboard event handling

**Trade-offs:**
- ✅ iOS handles all keyboard positioning logic
- ✅ Works with iPad floating/undocked keyboards automatically (iOS 17+)
- ✅ Toolbar dismisses with keyboard naturally
- ✅ Follows Apple WWDC23 guidance (official recommendation)
- ❌ inputAccessoryView has limited height (~44pt typical); custom sizes need careful layout
- ❌ View hierarchy is split: toolbar lives in inputAccessoryView, not SwiftUI tree

**Example:**

```swift
func makeUIView(context: Context) -> UITextView {
    let tv = UITextView()

    // Create toolbar as SwiftUI, wrap in UIHostingController
    let toolbarController = UIHostingController(
        rootView: FormattingToolbar { command in
            context.coordinator.handleFormattingCommand(command, in: tv)
        }
    )

    // Set fixed height (standard toolbar height)
    toolbarController.view.frame = CGRect(
        x: 0, y: 0,
        width: UIScreen.main.bounds.width,
        height: 44
    )

    // Attach above keyboard
    tv.inputAccessoryView = toolbarController.view

    return tv
}
```

### Pattern 2: Coordinator as Command Dispatcher

**What:** Coordinator (NSObject + UITextViewDelegate) receives formatting commands from SwiftUI toolbar via closure and dispatches to FormattingService, maintaining the separation between UI and business logic.

**When to use:**
- Need to bridge SwiftUI events to UIKit logic
- Multiple views might trigger the same business logic
- Want to test logic independently from UI

**Trade-offs:**
- ✅ Decouples FormattingToolbar from FormattingService
- ✅ Coordinator already manages UITextViewDelegate—natural place to dispatch
- ✅ Easier to test: mock Coordinator or inject FormattingService
- ❌ Extra indirection: toolbar → Coordinator → FormattingService (3 layers)

**Example:**

```swift
final class Coordinator: NSObject, UITextViewDelegate {
    @Binding var text: String
    let font: UIFont
    var isHighlightingEnabled: Bool

    func handleFormattingCommand(_ command: FormattingCommand, in textView: UITextView) {
        // Dispatch to service
        switch command {
        case .bold:
            FormattingService.applyBold(to: textView)
        case .italic:
            FormattingService.applyItalic(to: textView)
        // ...
        }

        // Sync binding (triggers highlighting, auto-save)
        self.text = textView.text
    }

    // Existing UITextViewDelegate methods unchanged
    func textViewDidChange(_ textView: UITextView) { ... }
}
```

### Pattern 3: Direct UITextView Mutation for Undo/Redo Support

**What:** FormattingService mutates `textView.text` (the property) instead of `textStorage.replaceCharacters()`. This preserves UITextView's automatic undo tracking.

**When to use:**
- Need undo/redo support without manual undo manager logic
- Operations are atomic (single text change)
- Performance is not the primary constraint

**Trade-offs:**
- ✅ UITextView's undoManager tracks changes automatically (no manual grouping for simple ops)
- ✅ Simple, reliable, few moving parts
- ✅ Existing app already uses this pattern (EditorView scheduleSave)
- ❌ Slightly slower than textStorage mutation (whole string reassignment)
- ❌ For multi-step operations (e.g., insert table), need explicit grouping

**Example:**

```swift
static func applyBold(to textView: UITextView) {
    let selectedRange = textView.selectedRange
    let text = textView.text
    let nsText = text as NSString

    // Calculate new text
    let newText = nsText.replacingCharacters(in: selectedRange, with: "**text**")

    // Mutate property (undoManager tracks this)
    textView.text = newText

    // Restore selection
    textView.selectedRange = NSRange(location: selectedRange.location, length: 0)
}
```

---

## Data Flow

### Toolbar Action → Text Mutation → Display Update

```
[User taps Bold button in FormattingToolbar]
         ↓
[FormattingToolbar.onFormat(.bold) closure called]
         ↓
[Coordinator.handleFormattingCommand(.bold, in: textView)]
         ↓
[FormattingService.applyBold(to: textView)]
  - Reads: selectedRange, text
  - Calculates: newText with ** wrapping
  - Mutates: textView.text = newText
  - UITextView.undoManager auto-records change
  - Restores: selectedRange
         ↓
[Coordinator.textViewDidChange() fires (UITextViewDelegate)]
  - self.text = textView.text (updates binding)
  - Starts highlighting debounce timer (0.3s)
         ↓
[MarkdownTextEditor.updateUIView() detects binding change]
  - Binding setter: doc.text = newValue
  - scheduleSave(for: doc) queued (1.5s delay)
         ↓
[EditorView detects doc.text change in binding]
  - Title updates with " *" (unsaved indicator)
         ↓
[After 0.3s: HighlightingService.applyMarkdownColors() runs]
  - Applies syntax colors to plain text
  - Preserves selectedRange
  - UITextView.attributedText updated
         ↓
[After 1.5s save delay: doc.updateChangeCount(.done)]
  - Triggers UIDocument auto-save mechanism
  - MarkdownDocument.contents(forType:) called
  - File written to disk
         ↓
[EditorView detects doc.hasUnsavedChanges = false]
  - Title updates (removes " *")
```

### Undo/Redo Flow

```
[User taps Undo button in FormattingToolbar]
         ↓
[FormattingService.undo(in: textView)]
  - Calls: textView.undoManager?.undo()
  - Restoration handled by iOS
         ↓
[UITextView restores previous text + selectedRange from undo stack]
         ↓
[textViewDidChange() fires (same as regular edit)]
  - Binding updated, highlighting/save scheduled
```

### Key Data Flows

1. **Toolbar → Text:** User taps button → Coordinator → FormattingService → textView.text mutation → undoManager tracks.
2. **Text → Binding:** textViewDidChange() reads textView.text, updates @Binding → EditorView binding setter → doc.text → save scheduling.
3. **Text → Display:** Binding change triggers updateUIView() → highlighting debounce → HighlightingService.applyMarkdownColors() → attributedText update.
4. **Undo/Redo:** FormattingService calls undoManager directly; iOS handles restoration; textViewDidChange() re-syncs binding.

---

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| 1–10 edits | Current approach works fine; undo stack is small |
| 10–100 edits | No change needed; UITextView handles undo stack |
| 100–1K edits | No change needed; undo stack grows (~10 MB typical) |
| 1K–10K edits | Monitor undo stack size; consider offering "Clear Undo History" if memory spikes |
| >10K edits | Unlikely in single session; if needed, trim undo manager or disable undo for large files |
| Large files (>500 KB) | Already handled: syntax highlighting disabled (existing safeguard) |

### Scaling Priorities

1. **First bottleneck:** Undo stack memory. Solution: Accept iOS default behavior (reasonable for local editing session) or add "Clear History" feature.
2. **Second bottleneck:** Highlighting performance. Solution: Already addressed (highlight disabled >500 KB).
3. **Unlikely bottleneck:** Toolbar rendering. SwiftUI/UIHostingController is fast for simple button layouts; not a concern.

---

## Anti-Patterns

### Anti-Pattern 1: Storing UITextView in SwiftUI @State

**What people do:**
```swift
@State var textView: UITextView?  // ❌ Can't store UIKit views in @State
```

**Why it's wrong:**
- UITextView is not Equatable; SwiftUI can't track changes
- Breaks when UIViewRepresentable recreates the view
- Creates unnecessary coupling between SwiftUI and UIKit

**Do this instead:**
```swift
// Keep reference local to makeUIView() or in Coordinator
let tv = UITextView()
// Reference only lives in closure scope or Coordinator
let closure = { context.coordinator.handle(..., in: tv) }
```

### Anti-Pattern 2: Mutating textStorage Instead of textView.text

**What people do:**
```swift
textView.textStorage.replaceCharacters(in: range, with: "**text**")  // ❌ Bypasses undo
```

**Why it's wrong:**
- Bypasses UITextView's property observer
- UITextView.undoManager doesn't track the change
- Requires manual `beginUndoGrouping()` + `registerUndo()` (complex, error-prone)

**Do this instead:**
```swift
let newText = (textView.text as NSString).replacingCharacters(in: range, with: "**text**")
textView.text = newText  // ✅ undoManager tracks automatically
```

### Anti-Pattern 3: Tight Coupling Between FormattingToolbar and UITextView

**What people do:**
```swift
struct FormattingToolbar: View {
    var textView: UITextView  // ❌ Couples SwiftUI to UIKit

    var body: some View {
        Button("Bold") {
            FormattingService.applyBold(to: textView)  // ❌ Direct reference
        }
    }
}
```

**Why it's wrong:**
- Forces SwiftUI to import/depend on UIKit types
- Breaks SwiftUI previews (can't mock UITextView easily)
- Difficult to test toolbar logic in isolation
- Violates separation of concerns

**Do this instead:**
```swift
struct FormattingToolbar: View {
    var onFormat: (FormattingCommand) -> Void  // ✅ Loose coupling via closure

    var body: some View {
        Button("Bold") {
            onFormat(.bold)
        }
    }
}
```

### Anti-Pattern 4: Doing Complex Text Operations Without Grouping Undo

**What people do:**
```swift
textView.text = text1  // Undo records this
textView.text = text2  // Undo records this separately
// User taps Undo twice to get to original state ❌ Confusing
```

**Why it's wrong:**
- Each mutation creates a separate undo entry
- User has to undo multiple times for a single "operation"
- Unintuitive UX

**Do this instead:**
```swift
textView.undoManager?.beginUndoGrouping()
textView.text = text1
textView.text = text2
textView.undoManager?.endUndoGrouping()
// User taps Undo once, both changes revert ✅
```

---

## Integration Points

### Files Changed

| File | Changes | Impact |
|------|---------|--------|
| `MarkdownTextEditor.swift` | Add `FormattingCommand` enum, modify `makeUIView()` to attach toolbar, add `handleFormattingCommand()` to Coordinator | Toolbar appears above keyboard |
| `FormattingToolbar.swift` | **NEW** — SwiftUI component with buttons and closure callback | UI for formatting buttons |
| `FormattingService.swift` | **NEW** — Static methods for text mutations (bold, italic, bullets, table, undo/redo) | Business logic for formatting |

### Files Unchanged

| File | Reason |
|------|--------|
| `EditorView.swift` | Toolbar is self-contained in MarkdownTextEditor; no changes needed to screen layout or state management |
| `AppState.swift` | Document lifecycle unchanged; no new state needed |
| `MarkdownDocument.swift` | File I/O unchanged |
| `HighlightingService.swift` | Syntax coloring logic unchanged; re-applied after mutations |
| `HomeView.swift` | File picker unchanged |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| **FormattingToolbar ↔ Coordinator** | Closure: `onFormat: (FormattingCommand) -> Void` | Loose coupling; toolbar doesn't know about UITextView |
| **Coordinator ↔ FormattingService** | Direct calls: `FormattingService.applyBold(to: textView)` | Coordinator is dispatcher; service is stateless |
| **FormattingService ↔ UITextView** | Direct mutation: `textView.text = newText` | Service is pure; no side effects except text mutation |
| **Coordinator ↔ MarkdownTextEditor Binding** | Property update: `self.text = textView.text` | Existing pattern (unchanged); triggers highlight and save |

---

## UITextView Reference Management

### How the Toolbar Gets a Reference to UITextView

1. **Creation Phase:**
   - MarkdownTextEditor.makeUIView() creates UITextView instance (`tv`)
   - Creates closure that captures `tv` in its scope
   - Wraps FormattingToolbar in UIHostingController
   - Passes closure to FormattingToolbar's `onFormat` parameter
   - Attaches toolbar to `tv.inputAccessoryView`

2. **Lifetime:**
   - Toolbar closure retains `tv` (captured in closure context)
   - As long as UITextView lives, closure lives
   - When UITextView is destroyed (EditorView dismissed), inputAccessoryView and closure are released

3. **Memory Safety:**
   - No explicit `weak` reference needed—`tv` is already owned by UIKit view hierarchy
   - Closure doesn't outlive the UITextView (they're destroyed together)
   - No retain cycles: toolbar → closure → tv (same ownership)

**Diagram:**

```
EditorView
  └─ MarkdownTextEditor (UIViewRepresentable)
      └─ UITextView (created in makeUIView)
          ├─ Delegate: Coordinator
          └─ inputAccessoryView: UIHostingController(FormattingToolbar)
              └─ closure captures: tv (UITextView)
                  └─ Calls: context.coordinator.handleFormattingCommand(cmd, in: tv)
```

---

## Testing Strategy

### Unit Tests

**FormattingService** (most testable):
```swift
// Test applyBold wraps selected text
let tv = UITextView()
tv.text = "hello world"
tv.selectedRange = NSRange(location: 0, length: 5)  // "hello"
FormattingService.applyBold(to: tv)
XCTAssertEqual(tv.text, "**hello** world")

// Test applyBold inserts markers at cursor if no selection
tv.text = "hello"
tv.selectedRange = NSRange(location: 5, length: 0)  // Cursor at end
FormattingService.applyBold(to: tv)
XCTAssertEqual(tv.text, "hello****")
```

**Coordinator** (integration test):
```swift
// Verify formatting command is dispatched correctly
let textView = UITextView()
let binding = Binding<String>(get: { "" }, set: { _ in })
let coordinator = Coordinator(text: binding, font: .systemFont(ofSize: 16), isHighlightingEnabled: true)
coordinator.handleFormattingCommand(.bold, in: textView)
// Verify textView.text was modified
```

**FormattingToolbar** (SwiftUI preview):
```swift
#Preview {
    FormattingToolbar { command in
        print("Tapped: \(command)")
    }
}
```

---

## Sources

- [Keep up with the keyboard - WWDC23](https://developer.apple.com/videos/play/wwdc2023/10281/)
- [Adjusting your layout with keyboard layout guide - Apple Developer Documentation](https://developer.apple.com/documentation/uikit/keyboards_and_input/adjusting_your_layout_with_keyboard_layout_guide)
- [selectedRange - Apple Developer Documentation](https://developer.apple.com/documentation/uikit/uitextview/1618615-selectedrange)
- [textView(_:shouldChangeTextIn:replacementText:) - UITextViewDelegate](https://developer.apple.com/documentation/uikit/uitextviewdelegate/1618630-textview)
- [Using coordinators to manage SwiftUI view controllers - Hacking with iOS](https://www.hackingwithswift.com/books/ios-swiftui/using-coordinators-to-manage-swiftui-view-controllers)
- [Importing interactive UIKit views into SwiftUI - Swift by Sundell](https://www.swiftbysundell.com/tips/importing-interactive-uikit-views-into-swiftui/)
- [How to use SwiftUI Coordinators to communicate with UIKit](https://tanaschita.com/20230508-coordinators-in-swiftui/)
- [What's new with text and text interactions - WWDC23](https://developer.apple.com/videos/play/wwdc2023/10058/)

---

*Architecture research for: iOS Markdown Editor v1.1 Formatting Toolbar*
*Researched: 2026-03-26*
