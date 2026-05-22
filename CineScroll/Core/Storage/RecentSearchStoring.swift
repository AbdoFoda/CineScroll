import Foundation

/// Persists recent movie search strings (max 10) for quick recall.
///
/// The protocol is intentionally `async` so that future backends (SwiftData, CloudKit, SQLite)
/// can do real I/O without requiring any changes to call sites.
/// Current implementations (UserDefaults, in-memory) have synchronous bodies. `await` on them
/// completes immediately without ever suspending.
protocol RecentSearchStoring: Sendable {
    /// Loads persisted recent searches (newest first).
    func loadQueries() async -> [String]

    /// Persists the full ordered list of recent searches.
    func saveQueries(_ queries: [String]) async
}


