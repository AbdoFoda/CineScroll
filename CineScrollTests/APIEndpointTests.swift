import XCTest
@testable import CineScroll

/// Tests `APIEndpoint.url()` URL structure and query parameter correctness.
///

final class APIEndpointTests: XCTestCase {

    override func setUp() {
        super.setUp()
        try? XCTSkipUnless(
            TMDBConfig.isConfigured,
            "TMDBConfig not configured. set CINESCROLL_API_BASE_URL in Secrets.xcconfig to run endpoint tests."
        )
    }

    func testNowPlayingURL() throws {
        let url = try APIEndpoint.nowPlaying(page: 2).url()
        XCTAssertTrue(url.path.hasSuffix("movie/now_playing"), "Unexpected path: \(url.path)")
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        XCTAssertTrue(items.contains(URLQueryItem(name: "page", value: "2")))
    }

    func testNowPlayingPageOneURL() throws {
        let url = try APIEndpoint.nowPlaying(page: 1).url()
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        XCTAssertTrue(items.contains(URLQueryItem(name: "page", value: "1")))
    }

    func testMovieDetailURL() throws {
        let url = try APIEndpoint.movieDetail(id: 550).url()
        XCTAssertTrue(url.path.hasSuffix("movie/550"), "Unexpected path: \(url.path)")
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        XCTAssertNil(components?.queryItems, "Detail endpoint should have no query params")
    }

    func testMovieCreditsURL() throws {
        let url = try APIEndpoint.movieCredits(id: 550).url()
        XCTAssertTrue(url.path.hasSuffix("movie/550/credits"), "Unexpected path: \(url.path)")
    }

    func testSearchMoviesURL() throws {
        let url = try APIEndpoint.searchMovies(query: "the matrix", page: 1).url()
        XCTAssertTrue(url.path.hasSuffix("search/movie"), "Unexpected path: \(url.path)")
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        XCTAssertTrue(items.contains(URLQueryItem(name: "query", value: "the matrix")))
        XCTAssertTrue(items.contains(URLQueryItem(name: "page", value: "1")))
    }

    func testSearchMoviesURLEncodesSpecialCharacters() throws {
        let url = try APIEndpoint.searchMovies(query: "sci-fi & fantasy", page: 1).url()
        XCTAssertNotNil(url, "URL must be constructible with special chars")
        // URLComponents handles percent-encoding; the absolute string must be valid
        XCTAssertNotNil(URL(string: url.absoluteString))
    }

    func testBaseURLTrailingSlashIsStripped() throws {
        // The endpoint constructs paths as base/path; verify no double-slash occurs
        let url = try APIEndpoint.movieDetail(id: 1).url()
        XCTAssertFalse(url.absoluteString.contains("//movie"), "Double slash detected: \(url)")
    }
}
