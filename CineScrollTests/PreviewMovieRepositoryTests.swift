import XCTest

@testable import CineScroll

final class PreviewMovieRepositoryTests: XCTestCase {
    func testNowPlayingReturnsTenMovies() async throws {
        let repo = PreviewMovieRepository()
        let page = try await repo.fetchNowPlaying(page: 1)
        XCTAssertEqual(page.results.count, 10)
    }

    func testSearchMatchesTitleLocally() async throws {
        let repo = PreviewMovieRepository()
        let page = try await repo.searchMovies(query: "dark", page: 1)
        XCTAssertEqual(page.results.count, 1)
        XCTAssertEqual(page.results.first?.title, "The Dark Knight")
    }

    func testSearchEmptyQueryReturnsNoResults() async throws {
        let repo = PreviewMovieRepository()
        let page = try await repo.searchMovies(query: "   ", page: 1)
        XCTAssertTrue(page.results.isEmpty)
    }
}
