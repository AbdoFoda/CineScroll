import XCTest
import Synchronization
@testable import CineScroll

/// Extended tests for `MovieRepositoryImpl` covering HTTP status-code mapping,
/// decoding failures, cache fallback, retry integration, and cast ordering.
final class MovieRepositoryImplExtendedTests: XCTestCase {

    // MARK: - Helpers

    private func makeResponse(status: Int, for request: URLRequest, headers: [String: String] = [:]) -> HTTPURLResponse {
        HTTPURLResponse(
            url: request.url ?? URL(string: "https://example.com")!,
            statusCode: status,
            httpVersion: nil,
            headerFields: headers
        )!
    }

    private func emptyOKClient() -> MockHTTPClient {
        MockHTTPClient { request in
            let resp = HTTPURLResponse(
                url: request.url ?? URL(string: "https://example.com")!,
                statusCode: 200, httpVersion: nil, headerFields: nil
            )!
            return (Data(), resp)
        }
    }

    // MARK: - HTTP status-code mapping

    func testStatus429ThrowsRateLimited() async throws {
        let client = MockHTTPClient { request in
            let resp = HTTPURLResponse(
                url: request.url ?? URL(string: "https://example.com")!,
                statusCode: 429, httpVersion: nil,
                headerFields: ["Retry-After": "30"]
            )!
            return (Data(), resp)
        }
        let repo = MovieRepositoryImpl(http: client, retryPolicy: .none)
        do {
            _ = try await repo.fetchNowPlaying(page: 1)
            XCTFail("Expected rateLimited")
        } catch NetworkError.rateLimited(let retryAfter) {
            XCTAssertEqual(retryAfter, 30)
        }
    }

    func testStatus429WithoutRetryAfterHeader() async throws {
        let client = MockHTTPClient { request in
            let resp = HTTPURLResponse(
                url: request.url ?? URL(string: "https://example.com")!,
                statusCode: 429, httpVersion: nil, headerFields: nil
            )!
            return (Data(), resp)
        }
        let repo = MovieRepositoryImpl(http: client, retryPolicy: .none)
        do {
            _ = try await repo.fetchNowPlaying(page: 1)
            XCTFail("Expected rateLimited")
        } catch NetworkError.rateLimited(let retryAfter) {
            XCTAssertNil(retryAfter)
        }
    }

    func testStatus500ThrowsInvalidResponse() async throws {
        let client = MockHTTPClient { request in
            let resp = HTTPURLResponse(
                url: request.url ?? URL(string: "https://example.com")!,
                statusCode: 500, httpVersion: nil, headerFields: nil
            )!
            return (Data(), resp)
        }
        let repo = MovieRepositoryImpl(http: client, retryPolicy: .none)
        do {
            _ = try await repo.fetchNowPlaying(page: 1)
            XCTFail("Expected invalidResponse")
        } catch NetworkError.invalidResponse(let code) {
            XCTAssertEqual(code, 500)
        }
    }

    func testStatus404ThrowsInvalidResponse() async throws {
        let client = MockHTTPClient { request in
            let resp = HTTPURLResponse(
                url: request.url ?? URL(string: "https://example.com")!,
                statusCode: 404, httpVersion: nil, headerFields: nil
            )!
            return (Data(), resp)
        }
        let repo = MovieRepositoryImpl(http: client, retryPolicy: .none)
        do {
            _ = try await repo.fetchNowPlaying(page: 1)
            XCTFail("Expected invalidResponse")
        } catch NetworkError.invalidResponse(let code) {
            XCTAssertEqual(code, 404)
        }
    }

    func testNonHTTPResponseThrowsNoData() async throws {
        let client = MockHTTPClient { _ in
            // Return a plain URLResponse (not HTTPURLResponse)
            let resp = URLResponse(
                url: URL(string: "https://example.com")!,
                mimeType: nil,
                expectedContentLength: 0,
                textEncodingName: nil
            )
            return (Data(), resp)
        }
        let repo = MovieRepositoryImpl(http: client, retryPolicy: .none)
        do {
            _ = try await repo.fetchNowPlaying(page: 1)
            XCTFail("Expected noData")
        } catch NetworkError.noData {
            // Pass
        }
    }

    // MARK: - Decoding failures

    func testMalformedJSONThrowsDecodingFailed() async throws {
        let client = MockHTTPClient { request in
            let resp = HTTPURLResponse(
                url: request.url ?? URL(string: "https://example.com")!,
                statusCode: 200, httpVersion: nil, headerFields: nil
            )!
            return ("not json at all".data(using: .utf8)!, resp)
        }
        let repo = MovieRepositoryImpl(http: client, retryPolicy: .none)
        do {
            _ = try await repo.fetchNowPlaying(page: 1)
            XCTFail("Expected decodingFailed")
        } catch NetworkError.decodingFailed {
            // Pass
        }
    }

    func testWrongSchemaThrowsDecodingFailed() async throws {
        // Valid JSON but wrong structure for PagedResponse<Movie>
        let wrongJSON = #"{"unexpected_key": 42}"#
        let client = MockHTTPClient { request in
            let resp = HTTPURLResponse(
                url: request.url ?? URL(string: "https://example.com")!,
                statusCode: 200, httpVersion: nil, headerFields: nil
            )!
            return (wrongJSON.data(using: .utf8)!, resp)
        }
        let repo = MovieRepositoryImpl(http: client, retryPolicy: .none)
        do {
            _ = try await repo.fetchNowPlaying(page: 1)
            XCTFail("Expected decodingFailed")
        } catch NetworkError.decodingFailed {
            // Pass
        }
    }

    // MARK: - Cache fallback
    func testConnectivityErrorFallsBackToCache() async throws {
        try XCTSkipUnless(TMDBConfig.isConfigured, "Needs configured API URL to build exact cache key")

        // Build the exact URL that the repo will use (including query params)
        let targetURL = try APIEndpoint.nowPlaying(page: 1).url()
        let cachePayload = try FixtureLoader.data(named: "now_playing")

        var cacheRequest = URLRequest(url: targetURL, cachePolicy: .returnCacheDataDontLoad, timeoutInterval: 5)
        cacheRequest.httpMethod = "GET"
        let cachedHTTPResponse = HTTPURLResponse(
            url: targetURL,
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Cache-Control": "max-age=3600"]
        )!
        let cachedResponse = CachedURLResponse(response: cachedHTTPResponse, data: cachePayload)
        URLCache.shared.storeCachedResponse(cachedResponse, for: cacheRequest)
        defer { URLCache.shared.removeCachedResponse(for: cacheRequest) }

        // First request (network): throw offline.
        // Fallback request (cache): serve from URLCache directly.
        let client = MockHTTPClient { request in
            if request.cachePolicy == .returnCacheDataDontLoad {
                if let cached = URLCache.shared.cachedResponse(for: request) {
                    return (cached.data, cached.response)
                }
                throw NetworkError.offline
            }
            throw NetworkError.offline
        }
        let repo = MovieRepositoryImpl(http: client, retryPolicy: .none)
        let page = try await repo.fetchNowPlaying(page: 1)

        XCTAssertEqual(page.results.first?.title, "Alpha", "Should return cached data when offline")
    }

    func testConnectivityErrorWithNoCacheThrowsOffline() async throws {
        // Build the exact URL the repo uses, then remove any cached entry for it
        let targetURL: URL
        if TMDBConfig.isConfigured, let url = try? APIEndpoint.nowPlaying(page: 1).url() {
            targetURL = url
        } else {
            targetURL = TMDBConfig.apiBaseURL.appendingPathComponent("movie/now_playing")
        }
        var cacheRequest = URLRequest(url: targetURL, cachePolicy: .returnCacheDataDontLoad, timeoutInterval: 5)
        cacheRequest.httpMethod = "GET"
        URLCache.shared.removeCachedResponse(for: cacheRequest)

        let client = MockHTTPClient { _ in throw NetworkError.offline }
        let repo = MovieRepositoryImpl(http: client, retryPolicy: .none)
        do {
            _ = try await repo.fetchNowPlaying(page: 1)
            XCTFail("Expected offline error")
        } catch NetworkError.offline {
            // Pass
        }
    }

    // MARK: - Cast ordering and limit

    func testCastSortedByOrderAndLimitedToConfig() async throws {
        // Build a large unsorted cast list (12 members)
        let castMembers = (0 ..< 12).reversed().map { i in
            #"{"id": \#(i), "name": "Actor \#(i)", "order": \#(i)}"#
        }.joined(separator: ",")
        let creditsJSON = #"{"id": 1, "cast": [\#(castMembers)]}"#

        let detailJSON = try FixtureLoader.data(named: "movie_detail")
        let creditsData = creditsJSON.data(using: .utf8)!

        let client = MockHTTPClient { request in
            let path = request.url?.path ?? ""
            let resp = HTTPURLResponse(
                url: request.url ?? URL(string: "https://example.com")!,
                statusCode: 200, httpVersion: nil, headerFields: nil
            )!
            return (path.contains("/credits") ? creditsData : detailJSON, resp)
        }

        let repo = MovieRepositoryImpl(http: client, retryPolicy: .none)
        let detail = try await repo.fetchMovieDetail(id: 550)

        XCTAssertEqual(detail.topCast.count, MoviePresentationConfig.topCastNamesLimit)
        XCTAssertEqual(detail.topCast.first?.name, "Actor 0", "Cast must be sorted by order ascending")
        XCTAssertEqual(detail.topCast.last?.name, "Actor \(MoviePresentationConfig.topCastNamesLimit - 1)")
    }

    func testEmptyCastReturnsNoTopCastNames() async throws {
        let creditsJSON = #"{"id": 1, "cast": []}"#
        let detailJSON = try FixtureLoader.data(named: "movie_detail")

        let client = MockHTTPClient { request in
            let path = request.url?.path ?? ""
            let resp = HTTPURLResponse(
                url: request.url ?? URL(string: "https://example.com")!,
                statusCode: 200, httpVersion: nil, headerFields: nil
            )!
            return (path.contains("/credits") ? creditsJSON.data(using: .utf8)! : detailJSON, resp)
        }

        let repo = MovieRepositoryImpl(http: client, retryPolicy: .none)
        let detail = try await repo.fetchMovieDetail(id: 550)
        XCTAssertTrue(detail.topCast.isEmpty)
    }

    // MARK: - Retry integration (transport retried, offline not)
    func testTransportErrorIsRetriedByDefaultPolicy() async throws {
        let counter = Mutex<Int>(0)
        let successPayload = try FixtureLoader.data(named: "now_playing")

        let client = MockHTTPClient { request in
            let n = counter.withLock { c -> Int in c += 1; return c }
            if n < 3 {
                throw NetworkError.transport(underlyingDescription: "transient")
            }
            let resp = HTTPURLResponse(
                url: request.url ?? URL(string: "https://example.com")!,
                statusCode: 200, httpVersion: nil, headerFields: nil
            )!
            return (successPayload, resp)
        }

        let fastPolicy = RetryPolicy(
            maxAttempts: 3,
            baseDelay: .milliseconds(1),
            multiplier: 1,
            jitterFraction: 0
        )
        let repo = MovieRepositoryImpl(http: client, retryPolicy: fastPolicy)
        let page = try await repo.fetchNowPlaying(page: 1)
        XCTAssertEqual(page.results.first?.title, "Alpha")
        XCTAssertEqual(counter.withLock { $0 }, 3)
    }
}
