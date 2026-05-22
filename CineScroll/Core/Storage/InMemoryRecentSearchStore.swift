import Foundation
import Synchronization

/// In-memory store useful for previews and unit tests.
///
/// Uses `Mutex` for thread-safe access without actor overhead.
final class InMemoryRecentSearchStore: RecentSearchStoring, @unchecked Sendable {
    private let storage = Mutex<[String]>([])

    func loadQueries() async -> [String] {
        storage.withLock { $0 }
    }

    func saveQueries(_ queries: [String]) async {
        storage.withLock { $0 = queries }
    }
}
