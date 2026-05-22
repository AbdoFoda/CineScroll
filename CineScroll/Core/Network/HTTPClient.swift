import Foundation

/// Abstraction over `URLSession` for testability and strict concurrency boundaries.
protocol HTTPClient: Sendable {
    /// Performs an HTTP request and returns raw bytes plus the URL response.
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

/// Production `HTTPClient` backed by `URLSession`.
struct URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch let urlError as URLError {
            // Map no-connectivity URLErrors to .offline so they are treated as non-retryable
            // and immediately fall through to the cache, rather than burning retry budget.
            switch urlError.code {
            case .notConnectedToInternet,
                 .networkConnectionLost,
                 .dataNotAllowed,
                 .internationalRoamingOff:
                throw NetworkError.offline
            default:
                throw NetworkError.transport(underlyingDescription: urlError.localizedDescription)
            }
        } catch {
            throw NetworkError.transport(underlyingDescription: error.localizedDescription)
        }
    }
}
