import XCTest
import Synchronization
@testable import CineScroll

final class MovieListViewModelTests: XCTestCase {
    @MainActor
    func testLoadMoreIgnoredUntilNearEnd() async throws {
        let repo = CountingMovieRepository()
        let vm = MovieListViewModel(repository: repo)

        vm.onAppear()
        try await Task.sleep(for: .milliseconds(200))

        XCTAssertGreaterThanOrEqual(repo.nowPlayingCallCount, 1)
        let callsAfterInitial = repo.nowPlayingCallCount

        vm.triggerLoadMoreIfNeeded(currentIndex: 0)
        try await Task.sleep(for: .milliseconds(50))

        XCTAssertEqual(repo.nowPlayingCallCount, callsAfterInitial)

        vm.triggerLoadMoreIfNeeded(currentIndex: max(vm.movies.count - 1, 0))
        try await Task.sleep(for: .milliseconds(200))

        XCTAssertGreaterThan(repo.nowPlayingCallCount, callsAfterInitial)
    }

    @MainActor
    func testPaginationIncrementsPage() async throws {
        let repo = CountingMovieRepository()
        let vm = MovieListViewModel(repository: repo)

        vm.onAppear()
        try await Task.sleep(for: .milliseconds(200))

        let firstCount = vm.movies.count
        XCTAssertGreaterThan(firstCount, 0)

        vm.triggerLoadMoreIfNeeded(currentIndex: max(vm.movies.count - 1, 0))
        try await Task.sleep(for: .milliseconds(200))

        XCTAssertGreaterThanOrEqual(repo.nowPlayingCallCount, 2)
        XCTAssertGreaterThan(vm.movies.count, firstCount)
    }

    @MainActor
    func testErrorSurfaces() async throws {
        let repo = ThrowingMovieRepository()
        let vm = MovieListViewModel(repository: repo)

        vm.onAppear()
        try await Task.sleep(for: .milliseconds(200))

        if case .error = vm.paginationState {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected error state")
        }
    }
}

private final class CountingMovieRepository: MovieRepository, @unchecked Sendable {
    private let counter = Mutex<Int>(0)

    var nowPlayingCallCount: Int {
        counter.withLock { $0 }
    }

    func fetchNowPlaying(page: Int) async throws -> PagedResponse<Movie> {
        counter.withLock { $0 += 1 }

        let movies = (1 ... 5).map { id in
            Movie(
                id: id + page * 100,
                title: "Title \(id)-\(page)",
                overview: "",
                posterPath: nil,
                backdropPath: nil,
                releaseDate: nil,
                voteAverage: 7
            )
        }

        return PagedResponse(page: page, results: movies, totalPages: 3, totalResults: 15)
    }

    func fetchMovieDetail(id: Int) async throws -> MovieDetail {
        MovieDetail(
            id: id,
            title: "",
            overview: "",
            posterPath: nil,
            backdropPath: nil,
            releaseDate: nil,
            voteAverage: 0,
            runtimeMinutes: nil,
            genres: [],
            topCast: []
        )
    }

    func searchMovies(query: String, page: Int) async throws -> PagedResponse<Movie> {
        PagedResponse(page: 1, results: [], totalPages: 1, totalResults: 0)
    }
}

private final class ThrowingMovieRepository: MovieRepository, @unchecked Sendable {
    func fetchNowPlaying(page: Int) async throws -> PagedResponse<Movie> {
        throw NetworkError.noData
    }

    func fetchMovieDetail(id: Int) async throws -> MovieDetail {
        throw NetworkError.noData
    }

    func searchMovies(query: String, page: Int) async throws -> PagedResponse<Movie> {
        throw NetworkError.noData
    }
}
