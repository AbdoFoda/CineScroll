import Foundation

/// HTTP endpoints served by the CineScroll TMDB proxy (same paths as TMDB v3).
enum APIEndpoint: Sendable {
    case nowPlaying(page: Int)
    case movieDetail(id: Int)
    case movieCredits(id: Int)
    case movieVideos(id: Int)
    case searchMovies(query: String, page: Int)

    /// Fully qualified URL on the CineScroll proxy (no API key on device).
    func url() throws -> URL {
        guard TMDBConfig.isConfigured else {
            throw NetworkError.missingAPIKey
        }
        switch self {
        case let .nowPlaying(page):
            return try makeURL(path: "movie/now_playing", query: [
                URLQueryItem(name: "page", value: String(page)),
            ])
        case let .movieDetail(id):
            return try makeURL(path: "movie/\(id)", query: [])
        case let .movieCredits(id):
            return try makeURL(path: "movie/\(id)/credits", query: [])
        case let .movieVideos(id):
            return try makeURL(path: "movie/\(id)/videos", query: [])
        case let .searchMovies(query, page):
            return try makeURL(path: "search/movie", query: [
                URLQueryItem(name: "query", value: query),
                URLQueryItem(name: "page", value: String(page)),
            ])
        }
    }

    private func makeURL(path: String, query: [URLQueryItem]) throws -> URL {
        let base = TMDBConfig.apiBaseURL.absoluteString
        let trimmedBase = base.hasSuffix("/") ? String(base.dropLast()) : base
        let full = "\(trimmedBase)/\(path)"
        guard var components = URLComponents(string: full) else {
            throw NetworkError.invalidURL
        }
        components.queryItems = query.isEmpty ? nil : query
        guard let url = components.url else {
            throw NetworkError.invalidURL
        }
        return url
    }
}
