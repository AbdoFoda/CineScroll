import Foundation

/// Lightweight movie summary used in grids, search, and navigation.
struct Movie: Identifiable, Decodable, Hashable, Sendable {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let voteAverage: Double

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate = "release_date"
        case voteAverage = "vote_average"
    }
}

extension Movie {
    /// Builds an absolute poster URL at the requested size.
    func posterURL(size: TMDBImageSize = .w342) -> URL? {
        TMDBConfig.imageURL(path: posterPath, size: size)
    }

    /// Builds an absolute backdrop URL at the requested size.
    func backdropURL(size: TMDBImageSize = .w780) -> URL? {
        TMDBConfig.imageURL(path: backdropPath, size: size)
    }

    /// Locale-aware release date (e.g. "Jan 15, 2024"). Falls back to the raw
    /// ISO-8601 string if parsing fails, or `nil` when no date is present.
    var formattedReleaseDate: String? {
        guard let releaseDate, !releaseDate.isEmpty else { return nil }
        return Self.releaseDateFormatter.date(from: releaseDate)
            .map { Self.displayDateFormatter.string(from: $0) }
            ?? releaseDate
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
