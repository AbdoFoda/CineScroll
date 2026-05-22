import Foundation

// MARK: - Genre

struct Genre: Decodable, Hashable, Sendable, Equatable {
    let id: Int
    let name: String
}

// MARK: - CastMember

/// A single cast member as displayed on the detail screen.
struct CastMember: Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
    let profilePath: String?

    func profileURL(size: TMDBImageSize = .w185) -> URL? {
        TMDBConfig.imageURL(path: profilePath, size: size)
    }
}

// MARK: - TrailerInfo

/// YouTube trailer metadata. Constructed from the TMDB `/movie/{id}/videos` response.
struct TrailerInfo: Sendable, Equatable {
    let youtubeKey: String

    /// YouTube thumbnail.
    var thumbnailURL: URL? {
        URL(string: "https://img.youtube.com/vi/\(youtubeKey)/hqdefault.jpg")
    }

    /// Web URL that iOS opens in the YouTube app when installed, Safari otherwise.
    var watchURL: URL? {
        URL(string: "https://www.youtube.com/watch?v=\(youtubeKey)")
    }
}

// MARK: - MovieDetail

struct MovieDetail: Sendable, Equatable {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let voteAverage: Double
    let runtimeMinutes: Int?
    let genres: [Genre]
    let topCast: [CastMember]
    let trailer: TrailerInfo?

    init(
        id: Int,
        title: String,
        overview: String,
        posterPath: String?,
        backdropPath: String?,
        releaseDate: String?,
        voteAverage: Double,
        runtimeMinutes: Int?,
        genres: [Genre],
        topCast: [CastMember],
        trailer: TrailerInfo? = nil
    ) {
        self.id = id
        self.title = title
        self.overview = overview
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.releaseDate = releaseDate
        self.voteAverage = voteAverage
        self.runtimeMinutes = runtimeMinutes
        self.genres = genres
        self.topCast = topCast
        self.trailer = trailer
    }

    var formattedRuntime: String? {
        guard let runtimeMinutes, runtimeMinutes > 0 else { return nil }
        let hours = runtimeMinutes / 60
        let minutes = runtimeMinutes % 60
        if hours == 0 { return "\(minutes)m" }
        if minutes == 0 { return "\(hours)h" }
        return "\(hours)h \(minutes)m"
    }

    var formattedRating: String { String(format: "★ %.1f", voteAverage) }

    var genresLine: String { genres.map(\.name).joined(separator: ", ") }

    /// Locale-aware release date (e.g. "Jan 15, 2024"). Falls back to the raw
    /// ISO-8601 string if parsing fails, or `nil` when no date is present.
    var formattedReleaseDate: String? {
        guard let releaseDate, !releaseDate.isEmpty else { return nil }
        return Self.releaseDateFormatter.date(from: releaseDate)
            .map { Self.displayDateFormatter.string(from: $0) }
            ?? releaseDate
    }

    func posterURL(size: TMDBImageSize = .w342) -> URL? {
        TMDBConfig.imageURL(path: posterPath, size: size)
    }

    func backdropURL(size: TMDBImageSize = .w780) -> URL? {
        TMDBConfig.imageURL(path: backdropPath, size: size)
    }

    private static let releaseDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    private static let displayDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()
}

// MARK: - Decoding models

/// Decodes the `/movie/{id}` payload.
struct MovieDetailResponse: Decodable, Sendable {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let voteAverage: Double
    let runtime: Int?
    let genres: [Genre]

    private enum CodingKeys: String, CodingKey {
        case id, title, overview, runtime, genres
        case posterPath   = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate  = "release_date"
        case voteAverage  = "vote_average"
    }
}

/// Decodes `/movie/{id}/credits` cast list.
struct CreditsResponse: Decodable, Sendable {
    let cast: [CastMemberResponse]

    struct CastMemberResponse: Decodable, Sendable {
        let id: Int
        let name: String
        let order: Int
        let profilePath: String?

        private enum CodingKeys: String, CodingKey {
            case id, name, order
            case profilePath = "profile_path"
        }
    }
}

/// Decodes `/movie/{id}/videos`. only YouTube trailers are used.
struct VideosResponse: Decodable, Sendable {
    let results: [VideoResult]

    struct VideoResult: Decodable, Sendable {
        let key: String
        let site: String
        let type: String
        let official: Bool?
    }
}

