import Foundation

/// Stable identifiers for UI tests and accessibility tooling.
/// Keep in sync with `CineScrollUITests/UITestID.swift`.
enum AccessibilityID {
    static let rootTabView = "root.tabView"
    static let tabNowPlaying = "tab.nowPlaying"
    static let tabSearch = "tab.search"

    static let nowPlayingGrid = "nowPlaying.grid"
    static let nowPlayingLoadingMore = "nowPlaying.loadingMore"

    static let searchRoot = "search.root"
    static let searchField = "search.field"
    static let searchRecentSection = "search.recent"
    static let searchResultsSection = "search.results"
    static let searchEmptyState = "search.emptyState"
    static let searchNoResultsState = "search.noResults"

    static let detailRoot = "detail.root"
    static let detailLoading = "detail.loading"

    static let errorRetry = "error.retry"
    static let networkBanner = "network.banner"

    static func movieCard(_ movieID: Int) -> String {
        "movieCard.\(movieID)"
    }

    static func recentChip(_ query: String) -> String {
        "search.recent.\(query)"
    }

    static func suggestionRow(_ movieID: Int) -> String {
        "search.suggestion.\(movieID)"
    }
}
