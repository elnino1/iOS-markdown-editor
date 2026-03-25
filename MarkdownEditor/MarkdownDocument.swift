import UIKit

// @unchecked Sendable: UIDocument is main-thread-only by convention; all mutations
// happen on the main actor via AppState. The @unchecked annotation satisfies the
// Swift concurrency checker without changing runtime behaviour.
class MarkdownDocument: UIDocument, @unchecked Sendable {
    var text: String = ""

    // Called by UIDocument when loading file content from disk
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        guard let data = contents as? Data else {
            throw CocoaError(.fileReadCorruptFile)
        }
        // Attempt UTF-8 first, fall back to latin1 to avoid silent corruption
        self.text = String(data: data, encoding: .utf8)
            ?? String(data: data, encoding: .isoLatin1)
            ?? ""
    }

    // Called by UIDocument when saving — return content to write to disk
    override func contents(forType typeName: String) throws -> Any {
        guard let data = text.data(using: .utf8) else {
            throw CocoaError(.fileWriteInapplicableStringEncoding)
        }
        return data
    }
}
