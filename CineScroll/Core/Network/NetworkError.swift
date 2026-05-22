import Foundation

/// Typed failures for networking and decoding in the TMDB stack.
enum NetworkError: Error, Equatable, Sendable {
    case invalidURL
    case invalidResponse(statusCode: Int)
    case decodingFailed(underlyingDescription: String)
    case noData
    case transport(underlyingDescription: String)
    case missingAPIKey
    /// Device has no usable network path (detected before a request is attempted).
    case offline
    /// Server returned HTTP 429. `retryAfter` is the value of the `Retry-After` header in seconds, if present.
    case rateLimited(retryAfter: TimeInterval?)

    var userFacingMessage: String {
        switch self {
        case .invalidURL:
            return "Could not build a valid request."
        case let .invalidResponse(code):
            return "Unexpected server response (\(code))."
        case .decodingFailed:
            return "Could not read the server data."
        case .noData:
            return "No data returned from the server."
        case .transport:
            return "A network error occurred. Check your connection."
        case .missingAPIKey:
            return "Set CINESCROLL_API_BASE_URL in Config/Secrets.xcconfig (see worker/README.md)."
        case .offline:
            return "You're offline. Check your connection and try again."
        case .rateLimited:
            return "Too many requests. Please wait a moment and try again."
        }
    }

    /// True for errors that are purely connectivity-related and worth retrying when back online.
    var isConnectivityError: Bool {
        switch self {
        case .transport, .offline: return true
        default: return false
        }
    }
}
