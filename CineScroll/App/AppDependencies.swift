import Foundation

/// Application-wide dependencies constructed once at launch.
struct AppDependencies: Sendable {
    let movieRepository: MovieRepository
    let recentSearchStore: RecentSearchStoring
    let networkMonitor: NetworkMonitor
    /// Debounce delay for the search field. Set to `.zero` in UITest builds to make
    /// search results appear synchronously, avoiding flakiness.
    let searchDebounceDelay: Duration

    /// Production wiring using `URLSession`, `UserDefaults`, and live reachability.
    static func live() -> AppDependencies {
        // Configure shared URLCache before any network call can be made.
        URLCache.shared.memoryCapacity = TMDBConfig.urlCacheMemoryCapacity
        URLCache.shared.diskCapacity = TMDBConfig.urlCacheDiskCapacity

        let monitor = NetworkMonitor()
        monitor.start()
        let http = URLSessionHTTPClient()
        let repo = MovieRepositoryImpl(http: http)
        let store = UserDefaultsRecentSearchStore()
        return AppDependencies(
            movieRepository: repo,
            recentSearchStore: store,
            networkMonitor: monitor,
            searchDebounceDelay: MoviePresentationConfig.searchDebounceDelay
        )
    }

    /// Lightweight wiring for SwiftUI previews (monitor not started. always reports connected).
    static func preview() -> AppDependencies {
        AppDependencies(
            movieRepository: PreviewMovieRepository(),
            recentSearchStore: InMemoryRecentSearchStore(),
            networkMonitor: NetworkMonitor(),
            searchDebounceDelay: MoviePresentationConfig.searchDebounceDelay
        )
    }

    /// Deterministic in-memory data for XCUITest (no network, instant search, fresh recents each launch).
    static func uiTest() -> AppDependencies {
        AppDependencies(
            movieRepository: PreviewMovieRepository(),
            recentSearchStore: InMemoryRecentSearchStore(),
            networkMonitor: NetworkMonitor(),
            searchDebounceDelay: .zero
        )
    }
}
