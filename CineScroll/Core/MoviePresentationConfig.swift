import Foundation

/// Display and data-shaping limits for the movie detail and search screens.
enum MoviePresentationConfig {
    /// Maximum cast member names shown in the detail header (ordered by billing).
    static let topCastNamesLimit = 8
    /// Maximum movie rows shown in the system autocomplete suggestion tray.
    static let autocompleteLimit = 8
    /// Maximum number of recent search queries persisted for quick recall.
    static let recentSearchesLimit = 10
    /// Debounce delay applied to the search field before a query is fired.
    static let searchDebounceDelay: Duration = .milliseconds(300)
}
