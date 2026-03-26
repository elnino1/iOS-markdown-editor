# Project Research Summary

**Project:** iOS Markdown Editor with Google Drive Integration (v1.0 completed through Phase 3 + v1.1 Formatting Toolbar enhancement)
**Domain:** iOS document editing app with cloud storage integration
**Researched:** 2026-03-26 (v1.1 toolbar update to prior 2026-03-25 v1.0 research)
**Confidence:** MEDIUM-HIGH (v1.0 core stack validated across 3 completed phases; v1.1 toolbar uses stable iOS APIs with clear implementation patterns)

## Executive Summary

The iOS Markdown Editor has successfully completed its v1.0 MVP (Phases 1-3: Auth → Browse with dot folders → Raw text editing) and is transitioning to v1.1 (Phase 4: Formatting toolbar). The project differentiates itself by enabling access to hidden dot folders in Google Drive—a use case that standard iOS file pickers deliberately exclude. The core architecture (SwiftUI frontend, UIDocument for file coordination, direct Google Drive REST API for dot folder access, Combine auto-save) is sound and battle-tested through Phase 3.

The v1.1 formatting toolbar feature adds production complexity through text manipulation and undo/redo management, but the risk is well-characterized and avoidable with strict adherence to three implementation patterns: (1) all text changes via UITextInput protocol methods (insertText, replace), never direct textStorage modification; (2) undo registration BEFORE text modification using atomic grouping for multi-step operations; (3) NSRange calculations always using NSString (UTF-16), not Swift String.count, to prevent emoji corruption. The recommended approach uses SwiftUI's native `.toolbar(placement: .keyboard)` modifier (iOS 15+) rather than UIKit's legacy inputAccessoryView pattern, avoiding unnecessary complexity while leveraging the project's iOS 16+ minimum.

Implementation success hinges on three mechanics: cursor position preservation across insertions (save before, recalculate offsets, restore after), NSRange handling of multi-byte characters, and avoiding feedback loops between toolbar actions and syntax highlighting (mitigated by existing 300ms debounce). These are well-documented patterns with clear code examples in STACK.md and PITFALLS.md. The critical pitfalls (undo stack corruption, cursor jumping, attribute loss) are high-severity but preventable with discipline. Phase 4 requires comprehensive testing across ASCII, emoji, CJK text, and multi-line selections before closing.

## Key Findings

### Recommended Stack

The v1.0 core stack (validated through Phase 3 execution) remains the foundation. The v1.1 toolbar adds only SwiftUI and iOS standard library components—no new external dependencies.

**Core technologies (v1.0, validated):**
- **Swift 5.10+** — Language with mature async/await patterns
- **SwiftUI (iOS 16+)** — Declarative UI framework; clean state management; integrates seamlessly with UIViewRepresentable wrapping of UITextView
- **UITextView (wrapped via UIViewRepresentable)** — Better performance than SwiftUI's TextEditor for large files; supports NSAttributedString for syntax highlighting; text insertion APIs integrate with UndoManager
- **UIDocument** — iOS standard for file coordination; atomic read/write to original location; handles concurrent access
- **Google Drive REST API v3** — Direct API access enables dot folder visibility; UIDocumentPickerViewController filters these out by default
- **Combine** — Reactive patterns for file I/O callbacks and debounced auto-save (1.5s debounce in EditorView.scheduleSave)
- **NSAttributedString + UITextView textStorage observer** — Markdown syntax highlighting with visual formatting

**New for v1.1 (Toolbar):**
- **SwiftUI `.toolbar` modifier (iOS 15+, recommended for iOS 16+)** — Native keyboard toolbar without UIKit bridging; automatically handles keyboard appearance/dismissal animations; cleaner than inputAccessoryView legacy approach
- **UITextInput protocol methods** (insertText, replace) — Standard text insertion APIs that integrate with UndoManager; MUST be used instead of direct textStorage modification
- **UndoManager (built-in)** — Tracks custom formatting operations if registered correctly (BEFORE text modification); atomic grouping via beginUndoGrouping/endUndoGrouping for multi-step operations

**Version constraints:**
- Minimum iOS 16.0 (project requirement; SwiftUI .toolbar fully supported)
- Xcode 15.1+
- No external dependencies required for toolbar feature

**What NOT to use:**
- ~~inputAccessoryView~~ — Legacy UIKit approach; adds UIViewRepresentable bridging complexity; SwiftUI .toolbar is simpler for iOS 16+ projects
- ~~Direct textStorage modification~~ — Bypasses UndoManager; breaks undo/redo; corrupts syntax highlighting state
- ~~Embedding webviews for auth~~ — Apple App Review rejection risk; security vulnerability

See STACK.md for detailed implementation patterns (bold/italic wrapping with marker insertion, bullet list prefixing, table templates, undo/redo registration order) and anti-patterns with code examples.

### Expected Features

**v1.0 Features (Phases 1-3, completed):**
- Google Drive OAuth2 authentication
- Browse Drive folder hierarchy with **dot folder visibility** (differentiator)
- Open and edit markdown files as raw text
- File metadata display
- Syntax highlighting (NSAttributedString-based)
- Auto-save via Combine debounce

**v1.1 Features (Phase 4, in planning):**
- **Formatting toolbar:** Bold, Italic, H1-H3 headers, Bullet lists, Numbered lists, Table insertion
- Undo/Redo buttons integrated with system undo stack
- Unsaved changes indicator updates on toolbar action
- Selection preservation across formatting operations

**Nice-to-have (if Phase 4 time permits, v1.1 polish):**
- Keyboard shortcuts (Command+B, Command+I, Command+Z, Command+F)
- Search/Find within file
- Undo/Redo button state management (disabled when stack empty)

**Explicitly defer to v2+:**
- Markdown preview / rendered output
- Local file caching for offline editing
- Multiple file tabs
- Real-time collaboration
- Custom themes beyond system light/dark
- Note-taking features (this is an editor, not a notes app)

See FEATURES.md for full feature landscape, MVP recommendation, and Google Drive-specific requirements.

### Architecture Approach

v1.0 established clean separation: **AuthManager** (OAuth token lifecycle) → **DriveManager** (Google Drive API) → **DriveFileCache** (metadata caching) → **BrowseViewController** (folder tree UI) → **FileSystemCoordinator** (ID-to-path mapping) → **TextEditorViewController** (text editing) → **EditorState** (ViewModel mediating file context) → **SyncManager** (uploads with conflict detection).

v1.1 extends this by adding formatting actions to the existing **TextEditorCoordinator** (already in the UIViewRepresentable pattern). The Coordinator manages the wrapped UITextView and already handles text delegate callbacks; formatting methods are a natural extension. SwiftUI toolbar (outside the UIViewRepresentable) calls these Coordinator methods, routing actions back to UITextView.

**Major components:**
1. **TextEditorCoordinator** (enhanced for v1.1) — Implements UITextViewDelegate; hosts text manipulation methods (applyBold, applyItalic, applyHeader, applyBullet, insertTable); manages selection preservation and undo registration
2. **EditorState (ViewModel)** — Tracks current file context; coordinate sync between UI and file state; routing for undo/redo updates to updateChangeCount
3. **HighlightingService** — Syntax highlighting via NSAttributedString observer; runs debounced (300ms) to avoid re-running during rapid toolbar actions; preserves selection during re-highlighting

**Key patterns for v1.1:**
- **Text insertion via UITextInput:** All formatting operations use `insertText()` or `replace()`, never direct textStorage mutation
- **Undo atomicity:** Multi-step operations (bold wrapping = two insertions) grouped via beginUndoGrouping/endUndoGrouping so they undo as one step
- **Selection preservation:** Save selectedRange before modification; recalculate positions accounting for inserted text; restore selectedRange after
- **NSRange vs NSString:** All position calculations use NSString (UTF-16 aware), not Swift String.count (grapheme-cluster aware) to handle emoji correctly
- **Highlighting debounce:** Toolbar actions don't immediately trigger highlighting re-run; existing 300ms debounce in textViewDidChange prevents visual flicker

See ARCHITECTURE.md for detailed data flow diagrams, auth flow, conflict resolution, and component interaction patterns.

### Critical Pitfalls

**Toolbar implementation introduces five high-severity pitfalls that can corrupt document state or destroy user trust:**

1. **Undo Stack Invalidation via Direct TextStorage Modification** (CRITICAL)
   - **The risk:** Toolbar code modifies `textView.textStorage` directly (e.g., `addAttribute()`, `replaceCharacters()`) instead of using UITextInput methods. Result: undo/redo becomes inconsistent. User presses Undo, text reverts but formatting doesn't, corrupting document state. Syntax highlighting observer may not fire correctly.
   - **How to avoid:** Use `UITextInput.insertText()` or `replace()` for ALL text changes. Register undo BEFORE modifying text using `undoManager.registerUndo(withTarget:handler:)`. For multi-step operations (bold wrapping), use atomic grouping: `beginUndoGrouping()` → insert → insert → `endUndoGrouping()` so all steps undo as one.
   - **Detection:** User applies bold formatting, presses Undo, text reverts but bold markers don't. Or undo stack grows incorrectly (toolbar actions appearing as multiple steps instead of one).

2. **Cursor Position Loss After NSRange-based Text Insertion** (CRITICAL)
   - **The risk:** Toolbar inserts opening marker at position 10, which shifts all subsequent text. Then tries to insert closing marker at position 10 + selection length, but the offset is wrong because the first insertion already shifted everything. Result: cursor jumps to end of document or selection is lost.
   - **How to avoid:** Save `selectedRange` BEFORE any modification. For multi-step insertion (bold = `**text**`), calculate both positions based on original range, then use atomic undo grouping to batch them. After all insertions complete, recalculate and restore selectedRange to the new position inside the markers.
   - **Detection:** After toolbar action, cursor jumps to end of text. Rapid toolbar clicks fail (second action inserts in wrong location or doesn't appear).

3. **Attributed String Highlighting Interfering with Toolbar Formatting** (HIGH)
   - **The risk:** Toolbar inserts `**bold**` markers. Syntax highlighting service re-runs, re-scanning entire document, and reassigns `attributedText`. This can reset `selectedRange` to 0, lose transient formatting, or create visual flicker.
   - **How to avoid:** Highlighting is already debounced (300ms delay) in current code (highlightTimer in MarkdownTextEditor.Coordinator). Selection is already preserved during re-highlighting. For toolbar actions, highlighting won't immediately re-run because textViewDidChange debounce timer is cancelled and restarted. This design is already in place and should not be changed.
   - **Detection:** Formatting appears briefly, then disappears as highlighting re-runs; visual flicker immediately after toolbar action.

4. **NSRange Off-by-One Errors with Emoji and Multi-Byte Characters** (MEDIUM)
   - **The risk:** Text contains emoji 👨‍👩‍👧 (8 UTF-16 units but Swift String.count = 1). NSRange uses UTF-16 positions. Insertion happens in middle of emoji, breaking it visually into separate pieces. Or selectedRange includes part of emoji, causing corruption.
   - **How to avoid:** Always use NSString (UTF-16 aware) for NSRange calculations. Never use Swift String.count for position math. Test extensively with multi-byte emoji: family emoji with ZWJ (👨‍👩‍👧), flag combinations (🏳️‍🌈), skin-tone modifiers (👩🏾‍💼, ☝🏽).
   - **Detection:** User inserts text near emoji, emoji breaks into separate pieces. Works fine with ASCII, breaks with emoji or CJK text.

5. **Incorrect Line Range Calculation for Bullet/Table Insertion** (MEDIUM)
   - **The risk:** Developer uses `String.split(separator: "\n")` which doesn't map to NSRange positions. Or calculates line end incorrectly. Result: bullet inserted on wrong line (off by 1), or multi-line selection only affects first line.
   - **How to avoid:** Use `NSString.lineRange(for:)` to find line boundaries from cursor position. For multi-line selection, find first and last lines, then process all lines in range. Preserve newline style (LF vs CRLF).
   - **Detection:** Bullet appears on wrong line after toolbar action. Multi-line selection (select 3 lines, apply bullet) only formats one line. Text looks corrupted after bullet/table insertion.

**Additional moderate/minor pitfalls** (see PITFALLS.md for details):
- textViewDidChange called 2-3 times per keystroke on iOS 17 with CJK keyboards (mitigated by 300ms debounce; recommend testing)
- selectedTextRange vs selectedRange confusion (stick with selectedRange throughout for consistency)
- Unsaved indicator lags (ensure toolbar actions call document.updateChangeCount(.done) immediately)
- Toolbar disappears after keyboard dismissal or rotation (edge case with inputAccessoryView; not relevant for SwiftUI .toolbar approach)

See PITFALLS.md for full implementation patterns with code examples, detection strategies, and comprehensive testing checklist.

## Implications for Roadmap

The project has completed Phases 1-3 (Auth, Browse, Edit with syntax highlighting). Phase 4 (Formatting Toolbar) is the recommended next phase. The phase structure remains unchanged from 2026-03-25 research; this update refines Phase 4 implementation details.

### Phase 1-3: Foundation, Browse, Edit (✓ COMPLETED)

Phases 1-3 validated:
- OAuth token refresh and Drive API integration
- Dot folder visibility working correctly via API (critical differentiator)
- UITextView with NSAttributedString highlighting performant for typical markdown files
- Combine-based auto-save debounce stable

No changes to completed phases.

### Phase 4: Formatting Toolbar (v1.1 — NEXT)

**Rationale:** Phase 3 delivers MVP raw text editor. Phase 4 adds table-stakes feature: formatting toolbar so users can insert markdown syntax via buttons instead of typing markers. Industry standard for markdown editors. Does not block v1.0 launch (can ship with raw text only) but essential for v1.1 competitiveness.

**Delivers:**
- SwiftUI toolbar with buttons: Bold, Italic, H1, H2, H3, Bullet, Numbered list, Table
- Each button calls TextEditorCoordinator method (applyBold, applyItalic, etc.)
- All text insertions use UITextInput methods; undo registration enforced
- Selection preservation across all formatting operations
- Unsaved changes indicator (`*` in title) updates immediately on toolbar action
- Undo/Redo buttons in toolbar that trigger system undo stack
- Comprehensive testing: ASCII + emoji + CJK; single-line + multi-line selections; large files (>100KB); rapid button clicks

**Stack elements used:**
- SwiftUI `.toolbar` modifier with `ToolbarItemGroup(placement: .keyboard)`
- UITextInput protocol (insertText, replace methods)
- UndoManager with beginUndoGrouping/endUndoGrouping
- NSString for range calculations

**Implements:**
- TextEditorCoordinator enhanced with formatting methods
- Toolbar placement in EditorView (outside UIViewRepresentable)
- Immediate updateChangeCount call on toolbar action

**Avoids critical pitfalls:**
- No direct textStorage modification
- Undo registered BEFORE text changes
- Selection saved/restored with offset recalculation
- NSRange calculations use NSString throughout
- Line ranges found via NSString.lineRange()
- No immediate highlighting re-run on toolbar action (existing debounce sufficient)

**Implementation approach:**
1. Add `.toolbar` modifier to EditorView with ToolbarItemGroup(placement: .keyboard)
2. Create formatting button targets: formatBold(), formatItalic(), formatHeader(level:), formatBullet(), formatNumberedList(), insertTable()
3. Each method: save selectedRange → register undo → insert via UITextInput → recalculate/restore selectedRange
4. For multi-step operations (bold wrapping), use atomic grouping
5. Call document.updateChangeCount(.done) immediately after each operation
6. Test extensively: emoji edge case (👨‍👩‍👧, 🏳️‍🌈, skin-tone variants); multi-line selection (select 3 lines, apply bullet); large file (>100KB, verify highlighting debounce works); rapid clicks (10+ toolbar button taps in 1 second)

**Estimated duration:** 2-3 weeks (implementation + testing)

**Research flags for Phase 4 execution:**
- Emoji text insertion edge cases — verify cursor position and syntax highlighting preserve correctly
- Multi-line selection bullet/table insertion — confirm all lines get formatted, not just first
- Large file performance — profile highlighting cost with >100KB file; verify debounce prevents lag
- iOS 17 CJK input method behavior — test on real iOS 17 device if possible (double-delegate-call risk)
- Real device testing — emoji handling may differ from simulator

### Phase 5: Polish (v1.1 Completion) — CONDITIONAL

**Rationale:** After Phase 4 toolbar ships, gather early user feedback. Phase 5 addresses practical improvements if data supports them.

**Potential additions (based on user feedback):**
- Keyboard shortcuts (Command+B, Command+I, Command+Z, Command+F) — easy addition; high power-user value
- Search/Find within file — moderate complexity; high utility for large documents
- Undo/Redo button state management (disable when stack empty) — UX refinement
- Syntax highlighting improvements (currently basic Markdown pattern matching)

**Do NOT add in Phase 5:**
- Preview features (defer to v2)
- Multiple file tabs (defer to v2)
- Offline sync (defer to v2)
- Custom themes (defer to v2)

### Phase Ordering Rationale

- **Phases 1-3 (completed):** Critical path: Auth → Browse → Edit. Each validates prior phase. Proves dot folder access works; proves UITextView editor is performant.
- **Phase 4 (toolbar):** Natural progression; users expect formatting in markdown editor. Blocks v1.1 release but not v1.0 MVP. Depends entirely on Phase 3 (UITextView already integrated; just adds button targets).
- **Phase 5 (polish):** Only after Phase 4 ships and early users validate workflow. Roadmap adjusts based on feedback.

### Research Flags

**Phases needing deeper research during Phase 4 execution:**
- **Emoji edge cases:** Recommend spike testing 👨‍👩‍👧, 🏳️‍🌈, skin-tone modifiers before full implementation. Unit tests should cover these.
- **Multi-line bullet formatting:** Recommend unit tests confirming all selected lines get bullet prefix, not just first.
- **Large file performance:** Recommend profiling with >100KB file to confirm highlighting debounce is sufficient.
- **iOS 17 CJK keyboards:** Recommend test on real iOS 17 device (simulator CJK behavior may differ) if available.

**Phases with standard patterns (skip deep research):**
- **Phases 1-3 (completed):** No research needed; implementations validated through execution.
- **Phase 5 (polish):** Keyboard shortcuts, search, and syntax highlighting are standard iOS patterns with ample documentation.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| **v1.0 Stack (Completed)** | HIGH | Swift, SwiftUI, UITextView, UIDocument, Google Drive API all validated through Phase 3 execution. Core architecture proved sound. |
| **v1.1 Toolbar Stack** | HIGH | SwiftUI .toolbar, UITextInput, UndoManager are stable iOS 16+ APIs with high community adoption. Implementation patterns clear with code examples. |
| **v1.0 Features** | HIGH | Phases 1-3 delivered all promised features. Dot folder access confirmed working. Raw text editing confirmed performant. |
| **v1.1 Features (Toolbar)** | HIGH | Feature scope clear (bold, italic, headers, bullets, tables). Implementation approach well-documented in STACK.md. No ambiguities. |
| **Architecture** | MEDIUM-HIGH | v1.0 architecture validated through Phase 3. v1.1 extension (Coordinator methods + toolbar modifier) is straightforward addition; no architectural changes needed. |
| **Pitfalls & Mitigations** | HIGH | Five critical pitfalls well-characterized with clear prevention patterns. Code examples provided in STACK.md and PITFALLS.md. High confidence in avoidability with discipline. |
| **Overall** | MEDIUM-HIGH | v1.0 core validated; v1.1 approach sound. Main risk is execution discipline on undo/cursor position handling during Phase 4 implementation. No architectural or technical blockers identified. |

### Gaps to Address

1. **Emoji handling validation** — Recommend unit tests with family emoji (👨‍👩‍👧), flag combinations (🏳️‍🌈), skin-tone variants (👩🏾, ☝🏽). Test both on simulator and real device (rendering may differ).

2. **Multi-line selection formatting** — Current architecture assumes single-line operations; multi-line bullet/table insertion needs careful line boundary handling. Phase 4 should include unit tests for 2-5 line selections with newline preservation.

3. **iOS 17 CJK keyboard behavior** — PITFALLS.md flags potential duplicate delegate calls on iOS 17 with Cangjie/Sucheng/Stroke keyboards. Existing 300ms debounce likely handles this, but recommend real device testing before Phase 4 closes.

4. **Large file performance with toolbar** — Phase 3 validated large files work without toolbar. Phase 4 must validate that toolbar actions don't trigger excessive highlighting re-runs. Recommend profiling with >100KB file.

5. **Undo/updateChangeCount interaction** — Current code has EditorView.scheduleSave() debounced at 1.5s. Unclear if toolbar actions call updateChangeCount immediately or wait for scheduleSave debounce. Phase 4 implementation should clarify this and route toolbar actions through binding if needed.

## Sources

### Primary (HIGH confidence)

- **Apple Developer Documentation** — UITextView, UndoManager, NSRange, UITextInput protocol, SwiftUI .toolbar modifier
- **WWDC 2022 (TextKit and Text Views)** — Official Apple guidance on text editing patterns
- **Apple Developer Forums** — Discussions of UndoManager integration, selectedRange handling, textViewDidChange callbacks

### Secondary (MEDIUM confidence)

- **Project STACK.md (2026-03-26)** — v1.1 toolbar research; detailed implementation patterns with code examples; validated against iOS markdown editor ecosystem
- **Project FEATURES.md (2026-03-25)** — Feature scope and MVP definition; based on iOS editor market conventions
- **Project ARCHITECTURE.md (2026-03-25)** — Component structure and data flow patterns; Google Drive integration validated in Phase 2 execution
- **Project PITFALLS.md (2026-03-26)** — Comprehensive pitfall research; grounded in developer forum discussions, official docs, and TextKit 2 edge cases
- **Project Phase 3 execution notes** — Validation of UITextView performance and NSAttributedString highlighting behavior

### Tertiary (MEDIUM-LOW, needs validation)

- **Google Drive API quota and file size limits** — Training knowledge; recommend official documentation review during Phase 4
- **iOS 17 CJK input method behavior** — Flagged in PITFALLS.md; recommend real device testing before Phase 4 closes

---

*Research completed: 2026-03-26*
*Researcher agents: STACK, FEATURES, ARCHITECTURE, PITFALLS (parallel research on v1.1 toolbar feature)*
*Previous research: 2026-03-25 (v1.0 phases 1-5)*
*Ready for Phase 4 planning: yes*
