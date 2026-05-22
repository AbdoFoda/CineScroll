import Foundation

/// UI-test element identifiers. keep in sync with `CineScroll/Shared/Accessibility/AccessibilityID.swift`.
enum UITestID {
    static let launchArgument = "-ui-testing"

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

    static let matrixMovieID = 101

    /// Preview catalog titles for UI-test fallbacks when querying by label.
    static func previewTitle(for movieID: Int) -> String {
        switch movieID {
        case 101: "The Matrix"
        case 102: "Inception"
        default: ""
        }
    }

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
