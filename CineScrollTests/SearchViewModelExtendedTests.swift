import XCTest
import Synchronization
@testable import CineScroll

@MainActor
final class SearchViewModelExtendedTests: XCTestCase {

    // MARK: - onAppear reloads recents from store

    func testOnAppearReloadsRecentsFromStore() async throws {
        let store = InMemoryRecentSearchStore()
        let vm = SearchViewModel(repository: EmptySearchRepository(), recentStore: store, debounceDelay: .zero)
        // Allow init Task to settle
        try await Task.sleep(for: .milliseconds(20))

        // Add query directly to store (bypassing VM)
        await store.saveQueries(["Inception"])
        XCTAssertTrue(vm.recentQueries.isEmpty, "VM loaded at init. store was empty then")

        vm.onAppear()
        // Allow onAppear Task to settle
        try await Task.sleep(for: .milliseconds(20))
        XCTAssertEqual(vm.recentQueries, ["Inception"], "onAppear must reload from store")
    }

    // MARK: - onDisappear cancels tasks

    func testOnDisappearCancelsPendingTasks() async throws {
        let repo = SlowSearchRepo()
        let store = InMemoryRecentSearchStore()
        let vm = SearchViewModel(repository: repo, recentStore: store, debounceDelay: .zero)

        vm.runQueryNow("matrix")
        try await Task.sleep(for: .milliseconds(10))
        vm.onDisappear()
        try await Task.sleep(for: .milliseconds(100))

        // After disappear, the fetch should be cancelled; state must not be .results
        XCTAssertNotEqual(vm.displayState, .results)
    }

    // MARK: - recordSelection

    func testRecordSelectionPersistsMovieTitle() async throws {
        let store = InMemoryRecentSearchStore()
        let vm = SearchViewModel(repository: EmptySearchRepository(), recentStore: store)
        let movie = Movie(id: 1, title: "Blade Runner", overview: "", posterPath: nil,
                          backdropPath: nil, releaseDate: nil, voteAverage: 8)

        vm.recordSelection(movie)
        // Allow the internal Task to persist to the store
        try await Task.sleep(for: .milliseconds(20))

        XCTAssertEqual(vm.recentQueries.first, "Blade Runner")
        let persisted = await store.loadQueries()
        XCTAssertEqual(persisted.first, "Blade Runner", "recordSelection must persist to store")
    }

    // MARK: - retryLastSearch

    func testRetryLastSearchWithQueryRerunsSearch() async throws {
        let repo = ControlledSearchRepoWithResult()
        let store = InMemoryRecentSearchStore()
        let vm = SearchViewModel(repository: repo, recentStore: store, debounceDelay: .zero)

        // Perform initial search to set lastQuery
        vm.runQueryNow("Matrix")
        try await Task.sleep(for: .milliseconds(80))
        XCTAssertEqual(vm.lastQuery, "Matrix")

        // Simulate connectivity error wiping results
        vm.connectivity.markError(.offline)

        // Retry
        vm.retryLastSearch()
        try await Task.sleep(for: .milliseconds(80))

        XCTAssertEqual(vm.displayState, .results)
    }

    func testRetryLastSearchWithEmptyQueryIsNoOp() async throws {
        let repo = ControlledSearchRepoWithResult()
        let store = InMemoryRecentSearchStore()
        let vm = SearchViewModel(repository: repo, recentStore: store, debounceDelay: .zero)

        XCTAssertTrue(vm.lastQuery.isEmpty)
        vm.retryLastSearch() // must not crash and must not change state
        try await Task.sleep(for: .milliseconds(50))

        XCTAssertEqual(vm.displayState, .idleEmptyQuery)
    }

    // MARK: - Offline preserves existing results

    func testConnectivityErrorPreservesPreviousResults() async throws {
        let repo = ConnectivityFailingSearchRepo()
        let store = InMemoryRecentSearchStore()
        let vm = SearchViewModel(repository: repo, recentStore: store, debounceDelay: .zero)

        // Manually inject previous results (simulate already-loaded state)
        repo.nextError = nil
        vm.runQueryNow("Batman")
        try await Task.sleep(for: .milliseconds(80))
        XCTAssertEqual(vm.displayState, .results)
        let countBefore = vm.results.count

        // Next search fails with connectivity error
        repo.nextError = .offline
        vm.runQueryNow("Batman 2")
        try await Task.sleep(for: .milliseconds(80))

        XCTAssertEqual(vm.results.count, countBefore, "Previous results must be preserved on connectivity error")
        XCTAssertEqual(vm.displayState, .results, "Display state must stay .results when results exist")
        XCTAssertNotNil(vm.connectivity.connectivityError)
    }

    func testConnectivityErrorWithNoResultsShowsIdleEmptyQuery() async throws {
        let repo = ConnectivityFailingSearchRepo()
        let store = InMemoryRecentSearchStore()
        let vm = SearchViewModel(repository: repo, recentStore: store, debounceDelay: .zero)

        repo.nextError = .offline
        vm.runQueryNow("NoCache")
        try await Task.sleep(for: .milliseconds(80))

        XCTAssertEqual(vm.displayState, .idleEmptyQuery, "No previous results → fall back to idle when offline")
        XCTAssertNotNil(vm.connectivity.connectivityError)
    }

    func testNonConnectivityErrorSetsErrorDisplayState() async throws {
        let repo = ConnectivityFailingSearchRepo()
        let store = InMemoryRecentSearchStore()
        let vm = SearchViewModel(repository: repo, recentStore: store, debounceDelay: .zero)

        repo.nextError = .decodingFailed(underlyingDescription: "bad json")
        vm.runQueryNow("test")
        try await Task.sleep(for: .milliseconds(80))

        if case .error = vm.displayState { } else {
            XCTFail("Non-connectivity error must set .error display state, got \(vm.displayState)")
        }
    }

    func testSuccessfulSearchAfterErrorShowsBackOnlineBanner() async throws {
        let repo = ConnectivityFailingSearchRepo()
        let store = InMemoryRecentSearchStore()
        let vm = SearchViewModel(repository: repo, recentStore: store, debounceDelay: .zero)

        // First search fails
        repo.nextError = .offline
        vm.runQueryNow("test")
        try await Task.sleep(for: .milliseconds(80))
        XCTAssertNotNil(vm.connectivity.connectivityError)

        // Second search succeeds
        repo.nextError = nil
        vm.runQueryNow("test2")
        try await Task.sleep(for: .milliseconds(80))

        XCTAssertTrue(vm.connectivity.isBackOnline, "reportSuccess after prior connectivity error must show banner")
        XCTAssertNil(vm.connectivity.connectivityError)
    }

    // MARK: - handleOffline branches

    func testHandleOfflineWithResultsKeepsResultsAndSetsError() async throws {
        let repo = ControlledSearchRepoWithResult()
        let store = InMemoryRecentSearchStore()
        let vm = SearchViewModel(repository: repo, recentStore: store, debounceDelay: .zero)

        vm.runQueryNow("Matrix")
        try await Task.sleep(for: .milliseconds(80))
        XCTAssertEqual(vm.displayState, .results)

        vm.connectivity.handleNetworkOffline()
        try await Task.sleep(for: .milliseconds(50))

        XCTAssertEqual(vm.displayState, .results, "Offline with results must keep .results state")
        XCTAssertEqual(vm.connectivity.connectivityError, .offline)
    }

    func testHandleOfflineWhileLoadingResetsToIdleAndSetsError() async throws {
        let repo = SlowSearchRepo()
        let store = InMemoryRecentSearchStore()
        let vm = SearchViewModel(repository: repo, recentStore: store, debounceDelay: .zero)

        vm.runQueryNow("Matrix")
        try await Task.sleep(for: .milliseconds(10))
        XCTAssertEqual(vm.displayState, .loading)

        vm.connectivity.handleNetworkOffline()
        try await Task.sleep(for: .milliseconds(50))

        XCTAssertEqual(vm.displayState, .idleEmptyQuery, "Offline while loading with no results → idle")
        XCTAssertEqual(vm.connectivity.connectivityError, .offline)
    }

    // MARK: - Recent queries dedup and limit

    func testPersistRecentDedupsCaseInsensitively() {
        let store = InMemoryRecentSearchStore()
        let vm = SearchViewModel(repository: EmptySearchRepository(), recentStore: store)

        vm.commitSearch("Matrix")
        vm.commitSearch("matrix")
        vm.commitSearch("MATRIX")

        XCTAssertEqual(vm.recentQueries.count, 1, "Case-insensitive duplicates must be merged")
        XCTAssertEqual(vm.recentQueries.first, "MATRIX", "Latest version must take precedence")
    }

    func testPersistRecentCapsAtTen() {
        let store = InMemoryRecentSearchStore()
        let vm = SearchViewModel(repository: EmptySearchRepository(), recentStore: store)

        for i in 1 ... 12 {
            vm.commitSearch("Query \(i)")
        }

        XCTAssertEqual(vm.recentQueries.count, 10, "Recent queries must be capped at 10")
        XCTAssertEqual(vm.recentQueries.first, "Query 12", "Most recent must be first")
    }

    func testCommitSearchIgnoresBlankQuery() {
        let store = InMemoryRecentSearchStore()
        let vm = SearchViewModel(repository: EmptySearchRepository(), recentStore: store)

        vm.commitSearch("   ")
        XCTAssertTrue(vm.recentQueries.isEmpty)
    }

    // MARK: - runQueryNow saves to recents on noResults

    func testRunQueryNowSaveToRecentsTrueOnNoResults() async throws {
        let repo = EmptySearchRepository()
        let store = InMemoryRecentSearchStore()
        let vm = SearchViewModel(repository: repo, recentStore: store, debounceDelay: .zero)

        vm.runQueryNow("Xzyzqp99", saveToRecents: true)
        try await Task.sleep(for: .milliseconds(80))

        XCTAssertEqual(vm.displayState, .noResults)
        XCTAssertEqual(vm.recentQueries.first, "Xzyzqp99", "saveToRecents must persist on .noResults too")
    }
}

// MARK: - Repository doubles

private final class EmptySearchRepository: MovieRepository, @unchecked Sendable {
    func fetchNowPlaying(page: Int) async throws -> PagedResponse<Movie> {
        PagedResponse(page: 1, results: [], totalPages: 1, totalResults: 0)
    }
    func fetchMovieDetail(id: Int) async throws -> MovieDetail {
        throw NetworkError.noData
    }
    func searchMovies(query: String, page: Int) async throws -> PagedResponse<Movie> {
        PagedResponse(page: 1, results: [], totalPages: 1, totalResults: 0)
    }
}

private final class SlowSearchRepo: MovieRepository, @unchecked Sendable {
    func fetchNowPlaying(page: Int) async throws -> PagedResponse<Movie> {
        PagedResponse(page: 1, results: [], totalPages: 1, totalResults: 0)
    }
    func fetchMovieDetail(id: Int) async throws -> MovieDetail { throw NetworkError.noData }
    func searchMovies(query: String, page: Int) async throws -> PagedResponse<Movie> {
        try await Task.sleep(for: .seconds(30))
        throw CancellationError()
    }
}

private final class ControlledSearchRepoWithResult: MovieRepository, @unchecked Sendable {
    func fetchNowPlaying(page: Int) async throws -> PagedResponse<Movie> {
        PagedResponse(page: 1, results: [], totalPages: 1, totalResults: 0)
    }
    func fetchMovieDetail(id: Int) async throws -> MovieDetail { throw NetworkError.noData }
    func searchMovies(query: String, page: Int) async throws -> PagedResponse<Movie> {
        let movie = Movie(id: 1, title: "The Matrix", overview: "", posterPath: nil,
                          backdropPath: nil, releaseDate: nil, voteAverage: 8)
        return PagedResponse(page: 1, results: [movie], totalPages: 1, totalResults: 1)
    }
}

private final class ConnectivityFailingSearchRepo: MovieRepository, @unchecked Sendable {
    private let errorLock = Mutex<NetworkError?>(nil)

    var nextError: NetworkError? {
        get { errorLock.withLock { $0 } }
        set { errorLock.withLock { $0 = newValue } }
    }

    func fetchNowPlaying(page: Int) async throws -> PagedResponse<Movie> {
        PagedResponse(page: 1, results: [], totalPages: 1, totalResults: 0)
    }
    func fetchMovieDetail(id: Int) async throws -> MovieDetail { throw NetworkError.noData }
    func searchMovies(query: String, page: Int) async throws -> PagedResponse<Movie> {
        if let error = errorLock.withLock({ $0 }) {
            throw error
        }
        let movie = Movie(id: 1, title: "Hit", overview: "", posterPath: nil,
                          backdropPath: nil, releaseDate: nil, voteAverage: 7)
        return PagedResponse(page: 1, results: [movie], totalPages: 1, totalResults: 1)
    }
}
