import Foundation

/// In-memory TMDB stand-in for SwiftUI previews (10 titles, local name search).
struct PreviewMovieRepository: MovieRepository {
    private static let catalog = PreviewMovieCatalog.movies

    func fetchNowPlaying(page: Int) async throws -> PagedResponse<Movie> {
        guard page == 1 else {
            return PagedResponse(page: page, results: [], totalPages: 1, totalResults: Self.catalog.count)
        }
        return PagedResponse(
            page: 1,
            results: Self.catalog,
            totalPages: 1,
            totalResults: Self.catalog.count
        )
    }

    func fetchMovieDetail(id: Int) async throws -> MovieDetail {
        guard let movie = Self.catalog.first(where: { $0.id == id }) else {
            throw NetworkError.noData
        }
        return MovieDetail(
            id: movie.id,
            title: movie.title,
            overview: movie.overview,
            posterPath: movie.posterPath,
            backdropPath: movie.backdropPath,
            releaseDate: movie.releaseDate,
            voteAverage: movie.voteAverage,
            runtimeMinutes: 120,
            genres: [Genre(id: 1, name: "Preview")],
            topCast: [
                CastMember(id: 1, name: "Preview Lead",    profilePath: nil),
                CastMember(id: 2, name: "Preview Support", profilePath: nil),
            ]
        )
    }

    func searchMovies(query: String, page: Int) async throws -> PagedResponse<Movie> {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, page == 1 else {
            return PagedResponse(page: max(page, 1), results: [], totalPages: 1, totalResults: 0)
        }

        let matches = Self.catalog.filter { movie in
            movie.title.localizedCaseInsensitiveContains(trimmed)
        }

        return PagedResponse(
            page: 1,
            results: matches,
            totalPages: 1,
            totalResults: matches.count
        )
    }
}
