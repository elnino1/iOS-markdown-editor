# Technology Stack

**Project:** iOS Markdown Editor with Google Drive Integration
**Researched:** 2026-03-25
**Confidence:** MEDIUM (training data current to Feb 2025; recommend verification with Xcode 16 docs)

## Recommended Stack

### Core Framework & UI

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Swift | 5.10+ | Language | Latest stable version with async/await maturity |
| SwiftUI | iOS 16+ | UI Framework | Modern declarative UI; cleaner state management than UIKit for this use case; better integration with FileProvider framework |
| Combine | iOS 13+ | Reactive programming | Built-in, zero-dependency async patterns for Drive API callbacks |

### Google Drive Integration

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Google Drive REST API v3 | Latest | File/folder access, read/write | Official REST API avoids SDK bloat; supports dot-folder browsing via `spaces='drive'` parameter |
| GoogleSignIn (google-ios-sdk) | 7.0+ | OAuth 2.0 authentication | Official Google SDK; handles token refresh, scopes (Drive scopes: `https://www.googleapis.com/auth/drive.file`) |
| URLSession | Built-in | HTTP requests to Drive API | Standard library; no dependency bloat for API calls |

### Text Editing & Markdown

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| UITextView (wrapped in SwiftUI) | Built-in | Raw text editing | Better performance than SwiftUI's TextEditor for large files; supports attributed strings for toolbar-driven formatting |
| SwiftUI TextEditor | iOS 16+ | Alternative light-weight editing | Sufficient for MVP if file sizes stay <100KB; switch to UITextView if performance issues arise |
| [No markdown parser for v1] | — | Deferred to v2 | MVP requires raw editing only; preview/rendering is out of scope. When needed: consider cmark-swift, Down, or SwiftMarkdown |

### Storage & File Handling

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| FileProvider framework | iOS 11+ | Local caching of Drive files | Enables offline access; syncs changes back to Drive; handles cache invalidation |
| URLCache | Built-in | HTTP response caching | Reduces Drive API quota usage; recommended for folder listings |

### Data Management & State

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| SwiftData (or Core Data) | iOS 17+ / iOS 10+ | Local persistence | SwiftData for new projects (simpler), Core Data if iOS 16 support required. Store: auth tokens, file history, user preferences. NOT the markdown content itself (lives in Drive). |
| @StateObject / @EnvironmentObject | Built-in | UI state management | SwiftUI's standard patterns; sufficient for file browser/editor state |

### Networking & Async

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| async/await | Swift 5.5+ | Asynchronous operations | Cleaner than callbacks/closures for Drive API calls; standard in modern Swift |
| Error handling (Result type) | Swift 5.0+ | Error propagation | Built-in; avoids try-catch verbosity |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Kingfisher | 7.0+ | Image caching for folder icons | Optional: if app displays Drive folder/file icons. Defer to v2 if MVP is text-only |
| SwiftUIKit or WrappingHStack | — | Layout utilities | Optional: for toolbar layout (bold/italic/header buttons). SwiftUI's HStack may suffice |

---

## Alternatives Considered & Why Not

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| **UI Framework** | SwiftUI | UIKit | SwiftUI is standard for greenfield iOS 16+ projects; UIKit introduces boilerplate; SwiftUI integrates better with FileProvider |
| **Google Drive access** | Google Drive REST API + GoogleSignIn SDK | UIDocumentPickerViewController for iCloud Drive | UIDocumentPickerViewController only accesses iCloud Drive / Files app, NOT Google Drive directly. Drive API is required for cross-folder browsing & dot-folder access |
| **Google Drive auth** | GoogleSignIn SDK | Manual OAuth 2.0 + custom token handling | GoogleSignIn handles token refresh, scope management, and error cases automatically |
| **Text editing** | UITextView (SwiftUI wrapper) | SwiftUI TextEditor | UITextView is more performant for large files and better supports attributed strings (needed for toolbar formatting). TextEditor is fine for v1 if file sizes are small. |
| **Persistence** | SwiftData | Core Data | SwiftData is newer, simpler syntax, and maps better to Swift types. Core Data if iOS 16 support required. |
| **Markdown parsing** | [Deferred to v2] | Embed markdown parser now | MVP is raw text editing only. Adding markdown parsing (cmark-swift, Down, SwiftMarkdown) adds build time & complexity. Parse on v2. |

---

## Installation & Setup

### Core Dependencies

```bash
# Using CocoaPods (alternative: Swift Package Manager)
pod 'GoogleSignIn', '~> 7.0'
pod 'GoogleAPIClientForREST/Drive', '~> 3.0'
```

### Swift Package Manager (Recommended for 2025)

Add to `Package.swift`:

```swift
.package(url: "https://github.com/google/google-signin-ios.git", from: "7.0.0"),
.package(url: "https://github.com/googleapis/google-api-objectivec-client-for-rest.git", from: "3.0.0")
```

### Manual Setup: Xcode Project

1. **Google Cloud Console Setup**
   - Create OAuth 2.0 credential (iOS app)
   - Add app bundle ID
   - Download client ID config

2. **GoogleSignIn Configuration**
   ```swift
   // In SceneDelegate or App.swift
   import GoogleSignIn

   GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: "YOUR_CLIENT_ID.apps.googleusercontent.com")
   ```

3. **Info.plist**
   - Add `GIDClientID`
   - Add URL schemes for OAuth redirect

---

## Key Technology Decisions

### 1. Google Drive API vs UIDocumentPickerViewController

**Decision: Use Google Drive REST API v3 + GoogleSignIn SDK**

**Rationale:**
- UIDocumentPickerViewController accesses **iCloud Drive only** (Files app integration). It cannot access Google Drive.
- Google Drive API is the **only way** to programmatically access Google Drive from iOS.
- Dot-folder support is possible via Drive API's `spaces='drive'` parameter and proper scoping; UIDocumentPicker filters them by default.
- Trade-off: Requires explicit OAuth setup vs UIDocumentPicker's automatic app sandbox integration.

**Implementation:**
```swift
// Pseudo-code: Folder listing with dot-folder support
let driveService = GTLRDriveService()
driveService.authorizer = user.authorization

let query = GTLRDriveQuery_FilesList()
query.spaces = "drive"
query.pageSize = 1000
// Query will include dot-folders automatically
driveService.executeQuery(query) { ... }
```

### 2. SwiftUI vs UIKit

**Decision: SwiftUI for primary UI, UITextView wrapper for editor**

**Rationale:**
- SwiftUI reduces boilerplate for file browser (NavigationStack, List)
- SwiftUI's @State/@StateObject fit the file editing workflow
- UITextView wrapped in UIViewRepresentable provides:
  - Better text performance for edits
  - Better formatting toolbar integration (attributed strings)
  - Fallback to TextEditor if performance proves acceptable in v1

**Implementation approach:**
```swift
// Primary editor wrapper
struct MarkdownEditorView: UIViewRepresentable {
    var text: Binding<String>
    var onFormat: (String) -> Void

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text.wrappedValue
    }
}
```

### 3. Text Formatting Toolbar

**Decision: Toolbar with selection-based formatting (no WYSIWYG for v1)**

**Approach:**
- Toolbar buttons (Bold, Italic, Header, Bullets) insert markdown syntax
- Example: Select text, tap "Bold" → wraps with `**text**`
- Uses UITextView's `selectedRange` property
- No live preview needed for v1

### 4. File Persistence & Caching

**Decision: FileProvider framework + URLCache**

**Rationale:**
- FileProvider syncs Drive files locally for offline access
- URLCache reduces Drive API quota usage for repeated folder listings
- SwiftData stores auth tokens and user preferences, NOT markdown content

---

## Dependencies Not Recommended (Why)

| Library | Why Not |
|---------|---------|
| Firebase | Adds backend dependency; project is Drive-only, no custom backend |
| Realm | Over-engineered for this scope; SwiftData is simpler |
| Alamofire | URLSession is sufficient; Alamofire adds complexity |
| Markdown parsers (Down, cmark-swift) | Deferred to v2 when preview is needed |
| Moya | Too heavy for simple REST API calls; URLSession + proper error handling is cleaner |

---

## Version Compatibility

- **Minimum iOS:** iOS 16.0 (SwiftUI TextEditor support)
- **Target iOS:** iOS 17.0+ (SwiftData, better async/await)
- **Swift:** 5.10+
- **Xcode:** 15.1+

---

## Build & Runtime Considerations

### App Transport Security
```xml
<!-- Info.plist: Allow Google Drive API over HTTPS (standard) -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSExceptionDomains</key>
    <dict>
        <key>googleapis.com</key>
        <dict>
            <key>NSIncludesSubdomains</key>
            <true/>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <false/>
        </dict>
    </dict>
</dict>
```

### Privacy & Permissions

```xml
<!-- Info.plist -->
<key>NSPhotoLibraryUsageDescription</key>
<string>Not used in v1</string>

<!-- Google Drive access requires explicit user consent via OAuth -->
<key>NSDocumentsDirectory</key>
<true/>
```

---

## Confidence Assessment

| Area | Level | Notes |
|------|-------|-------|
| **Swift/SwiftUI choice** | HIGH | Industry standard 2025-26 iOS stack |
| **Google Drive API v3** | HIGH | Official, well-documented; dot-folder support confirmed |
| **UITextView vs TextEditor** | MEDIUM | TextEditor may suffice for v1; UITextView recommended if file size/performance becomes issue |
| **FileProvider caching** | MEDIUM | Works well; implementation details should be validated during phase 1 |
| **No markdown parser v1** | HIGH | Clear scope constraint; defer to v2 |
| **SwiftData vs Core Data** | MEDIUM | SwiftData preferred but verify iOS 16 compatibility needs |

---

## Deferred Decisions (Phase 2+)

These technology choices should be revisited when those phases are implemented:

1. **Markdown rendering** (Preview feature)
   - Candidate: SwiftMarkdown, cmark-swift, Down
   - When: Phase 2 (preview feature)

2. **Syntax highlighting** (Enhanced editing)
   - Candidate: Sourcekit-LSP wrapper or custom highlighting
   - When: Phase 2-3 (if needed)

3. **Collaboration** (Multi-user editing)
   - Candidate: WebSocket sync layer, Operational Transformation library
   - When: Phase 3+ (if needed for multi-user support)

4. **Image/file embedding** (Rich media)
   - Candidate: FileProvider deep integration
   - When: Phase 3+ (if scope expands)

---

## Migration Path: TextEditor → UITextView

If SwiftUI TextEditor proves insufficient in v1:

```swift
// v1: SwiftUI TextEditor (fast iteration)
TextEditor(text: $fileContent)

// v1.x: Switch to UITextView wrapper if needed
MarkdownEditorView(text: $fileContent, onFormat: handleFormatting)
```

No breaking changes; same binding interface.

---

## Sources

- **Google Drive API:** [Google Drive REST API v3 documentation](https://developers.google.com/drive/api/guides/about-files) — official; dot-folder access via `spaces` parameter
- **GoogleSignIn SDK:** [google-ios-sdk GitHub](https://github.com/google/google-signin-ios) — version 7.0+, maintained
- **Swift/SwiftUI:** Apple's [Swift.org](https://www.swift.org) and [developer.apple.com/swiftui](https://developer.apple.com/swiftui) — current as of Xcode 15.1+
- **FileProvider:** Apple's [FileProvider documentation](https://developer.apple.com/documentation/fileprovider) — available iOS 11+
- **SwiftData:** Apple's [SwiftData documentation](https://developer.apple.com/documentation/swiftdata) — iOS 17+ recommended
