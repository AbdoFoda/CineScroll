import XCTest

@testable import CineScroll

final class MovieRepositoryTests: XCTestCase {
    func testNowPlayingDecodesFixture() async throws {
        let payload = try FixtureLoader.data(named: "now_playing")
        let client = MockHTTPClient { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://example.com")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (payload, response)
        }

        let repo = MovieRepositoryImpl(http: client)
        let page = try await repo.fetchNowPlaying(page: 1)

        XCTAssertEqual(page.page, 1)
        XCTAssertEqual(page.results.count, 2)
        XCTAssertEqual(page.results.first?.title, "Alpha")
    }

    func testMovieDetailMergesParallelResponses() async throws {
        let detail = try FixtureLoader.data(named: "movie_detail")
        let credits = try FixtureLoader.data(named: "movie_credits")

        let client = MockHTTPClient { request in
            let path = request.url?.path ?? ""
            let body: Data
            if path.contains("/credits") {
                body = credits
            } else {
                body = detail
            }
            let response = HTTPURLResponse(
                url: request.url ?? URL(string: "https://example.com")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (body, response)
        }

        let repo = MovieRepositoryImpl(http: client)
        let merged = try await repo.fetchMovieDetail(id: 550)

        XCTAssertEqual(merged.id, 550)
        XCTAssertEqual(merged.title, "Fight Club")
        XCTAssertEqual(merged.topCast.first?.name, "Edward Norton")
    }

    func testSearchDecodesFixture() async throws {
        let payload = try FixtureLoader.data(named: "search_movie")
        let client = MockHTTPClient { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://example.com")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (payload, response)
        }

        let repo = MovieRepositoryImpl(http: client)
        let page = try await repo.searchMovies(query: "test", page: 1)

        XCTAssertEqual(page.results.count, 1)
        XCTAssertEqual(page.results.first?.id, 99)
    }
}
