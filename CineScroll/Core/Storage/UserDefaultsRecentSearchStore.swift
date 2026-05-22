import Foundation

/// `UserDefaults`-backed recent search persistence.
///
/// `UserDefaults` is documented as thread-safe, so `@unchecked Sendable` is safe here.
/// Methods are `async` in signature to satisfy `RecentSearchStoring` but complete
/// synchronously without ever suspending. no actor overhead needed.
///
/// Schema versioning: data is stored under a versioned key (`cinescroll.recentSearches.v1`).
/// If the format changes in a future release, bump `currentVersion`, add a migration
/// case in `loadQueries()`, and write under the new key.
final class UserDefaultsRecentSearchStore: RecentSearchStoring, @unchecked Sendable {
    private let defaults: UserDefaults

    // Versioned storage key. Bump this and add a migration when the persisted shape changes.
    private static let currentVersion = 1
    private static var storageKey: String { "cinescroll.recentSearches.v\(currentVersion)" }
    // Legacy key written before versioning was added. migrated on first load then deleted.
    private static let legacyKey = "cinescroll.recentSearches"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadQueries() async -> [String] {
        // Migrate from the unversioned key written before v1.
        if let legacy = defaults.stringArray(forKey: Self.legacyKey) {
            defaults.set(legacy, forKey: Self.storageKey)
            defaults.removeObject(forKey: Self.legacyKey)
            return legacy
        }
        return defaults.stringArray(forKey: Self.storageKey) ?? []
    }

    func saveQueries(_ queries: [String]) async {
        defaults.set(queries, forKey: Self.storageKey)
    }
}
