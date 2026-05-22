import Foundation

/// Default TMDB-backed repository using a pluggable `HTTPClient`.
struct MovieRepositoryImpl: MovieRepository {
    private let http: HTTPClient
    private let decoder: JSONDecoder
    private let retryPolicy: RetryPolicy

    init(
        http: HTTPClient,
        decoder: JSONDecoder = MovieRepositoryImpl.makeDecoder(),
        retryPolicy: RetryPolicy = .default
    ) {
        self.http = http
        self.decoder = decoder
        self.retryPolicy = retryPolicy
    }

    func fetchNowPlaying(page: Int) async throws -> PagedResponse<Movie> {
        let data = try await performGET(.nowPlaying(page: page))
        return try decode(PagedResponse<Movie>.self, from: data)
    }

    func searchMovies(query: String, page: Int) async throws -> PagedResponse<Movie> {
        let data = try await performGET(.searchMovies(query: query, page: page))
        return try decode(PagedResponse<Movie>.self, from: data)
    }

    func fetchMovieDetail(id: Int) async throws -> MovieDetail {
        // All three requests fire concurrently; videos are best-effort.
        async let detailData  = performGET(.movieDetail(id: id))
        async let creditsData = performGET(.movieCredits(id: id))
        async let videosData  = fetchVideosSafely(id: id)

        let detail  = try decode(MovieDetailResponse.self, from: try await detailData)
        let credits = try decode(CreditsResponse.self,     from: try await creditsData)
        let topCast = credits.cast
            .sorted { $0.order < $1.order }
            .prefix(MoviePresentationConfig.topCastNamesLimit)
            .map { CastMember(id: $0.id, name: $0.name, profilePath: $0.profilePath) }

        let trailer: TrailerInfo?
        if let rawVideos = await videosData,
           let response = try? decode(VideosResponse.self, from: rawVideos) {
            trailer = pickTrailer(from: response)
        } else {
            trailer = nil
        }

        return MovieDetail(
            id: detail.id,
            title: detail.title,
            overview: detail.overview,
            posterPath: detail.posterPath,
            backdropPath: detail.backdropPath,
            releaseDate: detail.releaseDate,
            voteAverage: detail.voteAverage,
            runtimeMinutes: detail.runtime,
            genres: detail.genres,
            topCast: Array(topCast),
            trailer: trailer
        )
    }

    /// Videos fetch is fire-and-forget. a failure produces `nil` without
    /// surfacing an error to the caller.
    private func fetchVideosSafely(id: Int) async -> Data? {
        try? await performGET(.movieVideos(id: id))
    }

    /// Picks the best YouTube trailer: official trailer first, any trailer second.
    private func pickTrailer(from response: VideosResponse) -> TrailerInfo? {
        let youtubeTrailers = response.results.filter {
            $0.site == "YouTube" && $0.type == "Trailer"
        }
        let key = youtubeTrailers.first(where: { $0.official == true })?.key
            ?? youtubeTrailers.first?.key
        return key.map { TrailerInfo(youtubeKey: $0) }
    }

    // MARK: - Private

    private func performGET(_ endpoint: APIEndpoint) async throws -> Data {
        let url = try endpoint.url()

        // Always attempt the network. URLSessionHTTPClient maps no-connectivity URLErrors
        // to NetworkError.offline, which is non-retryable, so a truly offline request
        // fails immediately (< 100 ms) without burning the retry budget.
        // NWPathMonitor is used only to cancel tasks fast for UX, not to gate requests.
        do {
            return try await retryPolicy.execute {
                var request = URLRequest(url: url, timeoutInterval: 10)
                request.httpMethod = "GET"
                return try await fetchAndValidate(request)
            }
        } catch let networkError as NetworkError where networkError.isConnectivityError {
            // Network failed. serve stale cache so the user can keep browsing offline.
            return try await serveCached(url: url)
        }
    }

    /// Executes the request and maps HTTP status codes to typed errors.
    private func fetchAndValidate(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await http.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.noData
        }
        if httpResponse.statusCode == 401, !TMDBConfig.isConfigured {
            throw NetworkError.missingAPIKey
        }
        if httpResponse.statusCode == 429 {
            let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                .flatMap(TimeInterval.init)
            throw NetworkError.rateLimited(retryAfter: retryAfter)
        }
        guard (200 ... 299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse(statusCode: httpResponse.statusCode)
        }
        return data
    }

    /// Returns a cached response from `URLCache` without touching the network.
    /// Throws `NetworkError.offline` if no cached response exists.
    private func serveCached(url: URL) async throws -> Data {
        var request = URLRequest(url: url, cachePolicy: .returnCacheDataDontLoad, timeoutInterval: 5)
        request.httpMethod = "GET"
        do {
            return try await fetchAndValidate(request)
        } catch {
            throw NetworkError.offline
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(underlyingDescription: error.localizedDescription)
        }
    }

    private static func makeDecoder() -> JSONDecoder {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .useDefaultKeys
        return d
    }
}
