import Foundation

/// Persists up to 10 recently-opened file references using security-scoped bookmarks.
/// Bookmark data survives process restarts and security scope changes better than raw URLs.
/// Stored in UserDefaults under key "recentFilesBookmarks".
@MainActor
final class RecentFilesStore: ObservableObject {
    @Published private(set) var entries: [RecentFileEntry] = []

    private let maxCount = 10
    private let defaultsKey = "recentFilesBookmarks"

    init() {
        load()
    }

    /// Call after a successful open. Adds the URL to the front of the list,
    /// removes duplicates for the same file, and trims to maxCount.
    func add(url: URL) {
        // Create a bookmark so the entry survives security scope changes
        let bookmark = try? url.bookmarkData(
            options: .minimalBookmark,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        let entry = RecentFileEntry(
            filename: url.lastPathComponent,
            bookmark: bookmark,
            fallbackURL: url,
            lastOpenedAt: Date()
        )
        // Remove any existing entry for the same filename (best-effort dedup)
        entries.removeAll { $0.filename == entry.filename }
        // Prepend new entry
        entries.insert(entry, at: 0)
        // Trim to limit
        if entries.count > maxCount {
            entries = Array(entries.prefix(maxCount))
        }
        save()
    }

    /// Remove an entry at the given index set (for swipe-to-delete).
    func remove(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
        save()
    }

    /// Resolve an entry back to a URL (via bookmark, falls back to fallbackURL).
    func resolve(_ entry: RecentFileEntry) -> URL? {
        guard let bookmarkData = entry.bookmark else { return entry.fallbackURL }
        var isStale = false
        let resolved = try? URL(
            resolvingBookmarkData: bookmarkData,
            options: [],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        )
        return resolved ?? entry.fallbackURL
    }

    // MARK: - Persistence

    private func save() {
        let data = entries.compactMap { entry -> Data? in
            try? JSONEncoder().encode(entry)
        }
        UserDefaults.standard.set(data, forKey: defaultsKey)
    }

    private func load() {
        guard let dataArray = UserDefaults.standard.array(forKey: defaultsKey) as? [Data] else { return }
        entries = dataArray.compactMap { try? JSONDecoder().decode(RecentFileEntry.self, from: $0) }
    }
}

struct RecentFileEntry: Identifiable, Codable {
    let id: UUID
    let filename: String
    let bookmark: Data?
    let fallbackURL: URL
    let lastOpenedAt: Date

    init(filename: String, bookmark: Data?, fallbackURL: URL, lastOpenedAt: Date) {
        self.id = UUID()
        self.filename = filename
        self.bookmark = bookmark
        self.fallbackURL = fallbackURL
        self.lastOpenedAt = lastOpenedAt
    }
}
