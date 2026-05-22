import XCTest
import Synchronization
@testable import CineScroll

final class SearchViewModelTests: XCTestCase {
    @MainActor
    func testDebounceWaitsBeforeSearching() async throws {
        let repo = RecordingSearchRepository()
        let store = InMemoryRecentSearchStore()
        let vm = SearchViewModel(repository: repo, recentStore: store, debounceDelay: .milliseconds(120))

        vm.searchTextChanged("abc")
        try await Task.sleep(for: .milliseconds(30))
        XCTAssertEqual(repo.searchCalls, 0)

        try await Task.sleep(for: .milliseconds(150))
        XCTAssertEqual(repo.searchCalls, 1)
    }

    @MainActor
    func testCancellationPreventsStaleResults() async throws {
        let repo = SlowSearchRepository()
        let store = InMemoryRecentSearchStore()
        let vm = SearchViewModel(repository: repo, recentStore: store, debounceDelay: .milliseconds(0))

        vm.searchTextChanged("first")
        try await Task.sleep(for: .milliseconds(10))
        vm.searchTextChanged("second")
        try await Task.sleep(for: .milliseconds(300))

        XCTAssertEqual(vm.lastQuery, "second")
        XCTAssertEqual(vm.results.first?.title, "Second")
    }

    @MainActor
    func testMatchingRecentsFiltersByQuery() async {
        let store = InMemoryRecentSearchStore()
        await store.saveQueries(["Batman", "Matrix", "Batman Returns"])
        let vm = SearchViewModel(repository: RecordingSearchRepository(), recentStore: store)
        // Allow init's Task to load recents
        try? await Task.sleep(for: .milliseconds(20))

        XCTAssertEqual(vm.matchingRecents(for: "").count, 3)
        XCTAssertEqual(vm.matchingRecents(for: "bat").count, 2)
        XCTAssertTrue(vm.matchingRecents(for: "bat").allSatisfy { $0.localizedCaseInsensitiveContains("bat") })
    }

    @MainActor
    func testAutocompleteMoviesCapped() async throws {
        let repo = ManyResultsSearchRepository()
        let store = InMemoryRecentSearchStore()
        let vm = SearchViewModel(repository: repo, recentStore: store, debounceDelay: .milliseconds(0))

        vm.runQueryNow("star")
        try await Task.sleep(for: .milliseconds(100))

        XCTAssertEqual(vm.results.count, 12)
        XCTAssertEqual(vm.autocompleteMovies.count, MoviePresentationConfig.autocompleteLimit)
    }

    @MainActor
    func testRunQueryNowSaveToRecentsPersistsAfterSuccess() async throws {
        let store = InMemoryRecentSearchStore()
        let repo = ControlledSearchRepository()
        let vm = SearchViewModel(repository: repo, recentStore: store, debounceDelay: .zero)

        vm.runQueryNow("Matrix", saveToRecents: true)
        try await Task.sleep(for: .milliseconds(80))

        XCTAssertEqual(vm.recentQueries.first, "Matrix")
    }

    @MainActor
    func testCommitSearchPersistsRecent() {
        let store = InMemoryRecentSearchStore()
        let vm = SearchViewModel(repository: RecordingSearchRepository(), recentStore: store)

        vm.commitSearch("Inception")
        XCTAssertEqual(vm.recentQueries.first, "Inception")
    }

    @MainActor
    func testRunQueryNowIgnoresStaleEmptyDebounce() async throws {
        let repo = ControlledSearchRepository()
        let store = InMemoryRecentSearchStore()
        let vm = SearchViewModel(repository: repo, recentStore: store, debounceDelay: .milliseconds(50))

        vm.searchTextChanged("Matrix")
        vm.runQueryNow("Matrix")
        vm.searchTextChanged("")
        try await Task.sleep(for: .milliseconds(120))

        XCTAssertEqual(vm.displayState, .results)
        XCTAssertEqual(vm.results.first?.title, "Hit")
    }

    @MainActor
    func testEmptyVsNoResults() async throws {
        let repo = ControlledSearchRepository()
        let store = InMemoryRecentSearchStore()
        let vm = SearchViewModel(repository: repo, recentStore: store, debounceDelay: .milliseconds(0))

        vm.runQueryNow("   ")
        try await Task.sleep(for: .milliseconds(50))
        XCTAssertEqual(vm.displayState, .idleEmptyQuery)

        repo.nextEmpty = true
        vm.runQueryNow("nope")
        try await Task.sleep(for: .milliseconds(50))
        XCTAssertEqual(vm.displayState, .noResults)

        repo.nextEmpty = false
        vm.runQueryNow("yes")
        try await Task.sleep(for: .milliseconds(50))
        XCTAssertEqual(vm.displayState, .results)
    }
}

private final class RecordingSearchRepository: MovieRepository, @unchecked Sendable {
    private let counter = Mutex<Int>(0)

    var searchCalls: Int {
        counter.withLock { $0 }
    }

    func fetchNowPlaying(page: Int) async throws -> PagedResponse<Movie> {
        PagedResponse(page: 1, results: [], totalPages: 1, totalResults: 0)
    }

    func fetchMovieDetail(id: Int) async throws -> MovieDetail {
        MovieDetail(id: id, title: "", overview: "", posterPath: nil, backdropPath: nil, releaseDate: nil, voteAverage: 0, runtimeMinutes: nil, genres: [], topCast: [])
    }

    func searchMovies(query: String, page: Int) async throws -> PagedResponse<Movie> {
        counter.withLock { $0 += 1 }
        return PagedResponse(page: 1, results: [], totalPages: 1, totalResults: 0)
    }
}

private final class SlowSearchRepository: MovieRepository, @unchecked Sendable {
    func fetchNowPlaying(page: Int) async throws -> PagedResponse<Movie> {
        PagedResponse(page: 1, results: [], totalPages: 1, totalResults: 0)
    }

    func fetchMovieDetail(id: Int) async throws -> MovieDetail {
        MovieDetail(id: id, title: "", overview: "", posterPath: nil, backdropPath: nil, releaseDate: nil, voteAverage: 0, runtimeMinutes: nil, genres: [], topCast: [])
    }

    func searchMovies(query: String, page: Int) async throws -> PagedResponse<Movie> {
        try await Task.sleep(for: .milliseconds(120))
        let movie = Movie(
            id: query == "first" ? 1 : 2,
            title: query == "first" ? "First" : "Second",
            overview: "",
            posterPath: nil,
            backdropPath: nil,
            releaseDate: nil,
            voteAverage: 5
        )
        return PagedResponse(page: 1, results: [movie], totalPages: 1, totalResults: 1)
    }
}

private final class ManyResultsSearchRepository: MovieRepository, @unchecked Sendable {
    func fetchNowPlaying(page: Int) async throws -> PagedResponse<Movie> {
        PagedResponse(page: 1, results: [], totalPages: 1, totalResults: 0)
    }

    func fetchMovieDetail(id: Int) async throws -> MovieDetail {
        MovieDetail(id: id, title: "", overview: "", posterPath: nil, backdropPath: nil, releaseDate: nil, voteAverage: 0, runtimeMinutes: nil, genres: [], topCast: [])
    }

    func searchMovies(query: String, page: Int) async throws -> PagedResponse<Movie> {
        let movies = (1 ... 12).map { index in
            Movie(
                id: index,
                title: "Movie \(index)",
                overview: "",
                posterPath: nil,
                backdropPath: nil,
                releaseDate: "2020-01-01",
                voteAverage: 7
            )
        }
        return PagedResponse(page: 1, results: movies, totalPages: 1, totalResults: 12)
    }
}

private final class ControlledSearchRepository: MovieRepository, @unchecked Sendable {
    private let emptyFlag = Mutex<Bool>(false)

    var nextEmpty: Bool {
        get { emptyFlag.withLock { $0 } }
        set { emptyFlag.withLock { $0 = newValue } }
    }

    func fetchNowPlaying(page: Int) async throws -> PagedResponse<Movie> {
        PagedResponse(page: 1, results: [], totalPages: 1, totalResults: 0)
    }

    func fetchMovieDetail(id: Int) async throws -> MovieDetail {
        MovieDetail(id: id, title: "", overview: "", posterPath: nil, backdropPath: nil, releaseDate: nil, voteAverage: 0, runtimeMinutes: nil, genres: [], topCast: [])
    }

    func searchMovies(query: String, page: Int) async throws -> PagedResponse<Movie> {
        let empty = nextEmpty
        if empty {
            return PagedResponse(page: 1, results: [], totalPages: 1, totalResults: 0)
        }
        let movie = Movie(id: 3, title: "Hit", overview: "", posterPath: nil, backdropPath: nil, releaseDate: nil, voteAverage: 6)
        return PagedResponse(page: 1, results: [movie], totalPages: 1, totalResults: 1)
    }
}
