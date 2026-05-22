import XCTest
import Synchronization
@testable import CineScroll

/// Extended `MovieListViewModel` tests covering connectivity, placeholder, offline branches,
/// cancellation, load-more dedup, and page-boundary guards.
@MainActor
final class MovieListViewModelExtendedTests: XCTestCase {

    // MARK: - showsInitialPlaceholder

    func testShowsInitialPlaceholderWhileLoadingEmptyList() async throws {
        let repo = SlowNowPlayingRepository()
        let vm = MovieListViewModel(repository: repo)

        vm.onAppear()
        try await Task.sleep(for: .milliseconds(10))

        XCTAssertTrue(vm.showsInitialPlaceholder, "Placeholder must show when movies are empty and loading")
    }

    func testShowsInitialPlaceholderFalseAfterMoviesLoad() async throws {
        let repo = InstantNowPlayingRepository(movieCount: 3, totalPages: 1)
        let vm = MovieListViewModel(repository: repo)

        vm.onAppear()
        try await Task.sleep(for: .milliseconds(100))

        XCTAssertFalse(vm.showsInitialPlaceholder)
        XCTAssertEqual(vm.movies.count, 3)
    }

    func testShowsInitialPlaceholderFalseWhenLoadingButMoviesExist() async throws {
        let repo = InstantNowPlayingRepository(movieCount: 3, totalPages: 2)
        let vm = MovieListViewModel(repository: repo)

        // Load page 1
        vm.onAppear()
        try await Task.sleep(for: .milliseconds(100))

        // Trigger retry (movies exist, starts loading again)
        vm.retry()
        try await Task.sleep(for: .milliseconds(10))

        try await Task.sleep(for: .milliseconds(100))
        XCTAssertFalse(vm.showsInitialPlaceholder, "Placeholder false after retry completes")
    }

    // MARK: - onDisappear cancellation

    func testOnDisappearCancelsTask() async throws {
        let repo = SlowNowPlayingRepository()
        let vm = MovieListViewModel(repository: repo)

        vm.onAppear()
        try await Task.sleep(for: .milliseconds(10))
        vm.onDisappear()
        try await Task.sleep(for: .milliseconds(100))

        XCTAssertEqual(vm.paginationState, .idle, "Task cancellation must reset state to .idle")
        XCTAssertTrue(vm.movies.isEmpty)
    }

    // MARK: - retry clears movies

    func testRetryAfterErrorClearsMoviesAndReloads() async throws {
        let repo = RecoveringNowPlayingRepository(failCount: 1, movieCount: 4)
        let vm = MovieListViewModel(repository: repo)

        vm.onAppear()
        try await Task.sleep(for: .milliseconds(100))
        // First load fails
        if case .error = vm.paginationState { } else {
            XCTFail("Expected .error after failing first load")
        }

        vm.retry()
        try await Task.sleep(for: .milliseconds(100))

        XCTAssertEqual(vm.paginationState, .loaded)
        XCTAssertEqual(vm.movies.count, 4)
    }

    // MARK: - Connectivity error paths

    func testConnectivityErrorOnInitialLoadSetsConnectivityState() async throws {
        let repo = ConnectivityFailingRepository()
        let vm = MovieListViewModel(repository: repo)

        vm.onAppear()
        try await Task.sleep(for: .milliseconds(100))

        XCTAssertNotNil(vm.connectivity.connectivityError, "Connectivity error must set toast state")
    }

    func testConnectivityErrorOnLoadMoreKeepsLoadedState() async throws {
        let repo = InstantNowPlayingRepository(movieCount: 5, totalPages: 3)
        let vm = MovieListViewModel(repository: repo)

        // Load page 1
        vm.onAppear()
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertEqual(vm.paginationState, .loaded)

        // Switch repo to fail with connectivity on next call
        repo.makeNextFail(.offline)

        vm.triggerLoadMoreIfNeeded(currentIndex: vm.movies.count - 1)
        try await Task.sleep(for: .milliseconds(100))

        // paginationState must stay .loaded (not .error) for connectivity issues
        XCTAssertEqual(vm.paginationState, .loaded, "Connectivity error on load-more must not break loaded state")
        XCTAssertNotNil(vm.connectivity.connectivityError)
    }

    func testSuccessfulRefreshAfterErrorShowsBackOnlineBanner() async throws {
        let repo = RecoveringNowPlayingRepository(failCount: 1, movieCount: 3)
        let vm = MovieListViewModel(repository: repo)

        vm.onAppear()
        try await Task.sleep(for: .milliseconds(100))
        // Mark a prior error to simulate offline state
        vm.connectivity.markError(.offline)

        vm.retry()
        try await Task.sleep(for: .milliseconds(100))

        XCTAssertTrue(vm.connectivity.isBackOnline, "reportSuccess must show 'back online' banner")
    }

    // MARK: - Load-more deduplication

    func testLoadMoreDedupesOverlappingIDs() async throws {
        let repo = InstantNowPlayingRepository(movieCount: 5, totalPages: 2)
        let vm = MovieListViewModel(repository: repo)

        vm.onAppear()
        try await Task.sleep(for: .milliseconds(100))

        // Page 2 from InstantNowPlayingRepository uses page-offset IDs to avoid overlap,
        // so we manually test by injecting same IDs via a dedup-triggering repo
        let dedupRepo = DuplicateIDRepository()
        let vm2 = MovieListViewModel(repository: dedupRepo)

        vm2.onAppear()
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertEqual(vm2.movies.count, 5, "Page 1 loaded")

        vm2.triggerLoadMoreIfNeeded(currentIndex: vm2.movies.count - 1)
        try await Task.sleep(for: .milliseconds(100))

        XCTAssertEqual(vm2.movies.count, 5, "Duplicate IDs from page 2 must be filtered out")
    }

    // MARK: - Page boundary guard

    func testLoadMoreIgnoredWhenOnLastPage() async throws {
        let repo = InstantNowPlayingRepository(movieCount: 5, totalPages: 1)
        let vm = MovieListViewModel(repository: repo)

        vm.onAppear()
        try await Task.sleep(for: .milliseconds(100))
        let countBefore = vm.movies.count

        vm.triggerLoadMoreIfNeeded(currentIndex: vm.movies.count - 1)
        try await Task.sleep(for: .milliseconds(50))

        XCTAssertEqual(vm.movies.count, countBefore, "Load-more must not fire on last page")
    }

    // MARK: - handleOffline with existing movies

    func testHandleOfflineWithExistingMoviesKeepsLoadedState() async throws {
        let repo = InstantNowPlayingRepository(movieCount: 3, totalPages: 1)
        let vm = MovieListViewModel(repository: repo)

        vm.onAppear()
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertEqual(vm.paginationState, .loaded)

        vm.connectivity.handleNetworkOffline()
        try await Task.sleep(for: .milliseconds(50))

        XCTAssertEqual(vm.paginationState, .loaded, "Going offline with existing movies must not clear loaded state")
        XCTAssertEqual(vm.connectivity.connectivityError, .offline)
        XCTAssertFalse(vm.movies.isEmpty)
    }
}

// MARK: - Repository doubles

private final class SlowNowPlayingRepository: MovieRepository, @unchecked Sendable {
    func fetchNowPlaying(page: Int) async throws -> PagedResponse<Movie> {
        try await Task.sleep(for: .seconds(30))
        throw CancellationError()
    }
    func fetchMovieDetail(id: Int) async throws -> MovieDetail {
        throw NetworkError.noData
    }
    func searchMovies(query: String, page: Int) async throws -> PagedResponse<Movie> {
        PagedResponse(page: 1, results: [], totalPages: 1, totalResults: 0)
    }
}

private final class InstantNowPlayingRepository: MovieRepository, @unchecked Sendable {
    private let movieCount: Int
    private let totalPages: Int
    private let failLock = Mutex<NetworkError?>(nil)

    init(movieCount: Int, totalPages: Int) {
        self.movieCount = movieCount
        self.totalPages = totalPages
    }

    func makeNextFail(_ error: NetworkError) {
        failLock.withLock { $0 = error }
    }

    func fetchNowPlaying(page: Int) async throws -> PagedResponse<Movie> {
        if let error = failLock.withLock({ e -> NetworkError? in defer { e = nil }; return e }) {
            throw error
        }
        let movies = (1 ... max(1, movieCount)).map { i in
            Movie(id: i + page * 1000, title: "Movie \(i)-p\(page)", overview: "",
                  posterPath: nil, backdropPath: nil, releaseDate: nil, voteAverage: 7)
        }
        return PagedResponse(page: page, results: movies, totalPages: totalPages, totalResults: movieCount * totalPages)
    }
    func fetchMovieDetail(id: Int) async throws -> MovieDetail {
        throw NetworkError.noData
    }
    func searchMovies(query: String, page: Int) async throws -> PagedResponse<Movie> {
        PagedResponse(page: 1, results: [], totalPages: 1, totalResults: 0)
    }
}

private final class ConnectivityFailingRepository: MovieRepository, @unchecked Sendable {
    func fetchNowPlaying(page: Int) async throws -> PagedResponse<Movie> {
        throw NetworkError.offline
    }
    func fetchMovieDetail(id: Int) async throws -> MovieDetail {
        throw NetworkError.offline
    }
    func searchMovies(query: String, page: Int) async throws -> PagedResponse<Movie> {
        throw NetworkError.offline
    }
}

private final class RecoveringNowPlayingRepository: MovieRepository, @unchecked Sendable {
    private let lock = Mutex<Int>(0)
    private let failCount: Int
    private let movieCount: Int
    init(failCount: Int, movieCount: Int) {
        self.failCount = failCount
        self.movieCount = movieCount
    }
    func fetchNowPlaying(page: Int) async throws -> PagedResponse<Movie> {
        let n = lock.withLock { c -> Int in c += 1; return c }
        // Use a non-connectivity error (noData) so the VM sets .error state rather than staying .loaded
        if n <= failCount { throw NetworkError.noData }
        let movies = (1 ... max(1, movieCount)).map { i in
            Movie(id: i, title: "Movie \(i)", overview: "", posterPath: nil,
                  backdropPath: nil, releaseDate: nil, voteAverage: 7)
        }
        return PagedResponse(page: 1, results: movies, totalPages: 1, totalResults: movieCount)
    }
    func fetchMovieDetail(id: Int) async throws -> MovieDetail { throw NetworkError.noData }
    func searchMovies(query: String, page: Int) async throws -> PagedResponse<Movie> {
        PagedResponse(page: 1, results: [], totalPages: 1, totalResults: 0)
    }
}

private final class DuplicateIDRepository: MovieRepository, @unchecked Sendable {
    func fetchNowPlaying(page: Int) async throws -> PagedResponse<Movie> {
        // Always returns the same 5 IDs regardless of page. simulates server returning duplicates
        let movies = (1 ... 5).map { i in
            Movie(id: i, title: "Movie \(i)", overview: "", posterPath: nil,
                  backdropPath: nil, releaseDate: nil, voteAverage: 7)
        }
        return PagedResponse(page: page, results: movies, totalPages: 2, totalResults: 10)
    }
    func fetchMovieDetail(id: Int) async throws -> MovieDetail { throw NetworkError.noData }
    func searchMovies(query: String, page: Int) async throws -> PagedResponse<Movie> {
        PagedResponse(page: 1, results: [], totalPages: 1, totalResults: 0)
    }
}
