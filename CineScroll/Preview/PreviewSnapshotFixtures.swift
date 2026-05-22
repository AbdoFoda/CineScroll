import Foundation

/// Deterministic models for previews and snapshot tests.
enum PreviewSnapshotFixtures {
    static var matrix: Movie {
        PreviewMovieCatalog.movies[0]
    }

    static var inception: Movie {
        PreviewMovieCatalog.movies[1]
    }

    static var matrixDetail: MovieDetail {
        MovieDetail(
            id: matrix.id,
            title: matrix.title,
            overview: matrix.overview,
            posterPath: matrix.posterPath,
            backdropPath: matrix.backdropPath,
            releaseDate: matrix.releaseDate,
            voteAverage: matrix.voteAverage,
            runtimeMinutes: 136,
            genres: [
                Genre(id: 28, name: "Action"),
                Genre(id: 878, name: "Science Fiction"),
            ],
            topCast: [
                CastMember(id: 6384,  name: "Keanu Reeves",       profilePath: "/4D0PpNI0kmP58hgrwGC3wCjxhnm.jpg"),
                CastMember(id: 2975,  name: "Laurence Fishburne", profilePath: "/mh0lZ1XsT84FayMNiT6Erh91mVu.jpg"),
                CastMember(id: 70851, name: "Carrie-Anne Moss",   profilePath: "/8iATAc5z5XOeZMjkFKIQQBHKoq1.jpg"),
            ],
            trailer: TrailerInfo(youtubeKey: "m8e-FF8MsqU")
        )
    }

    /// Minimal detail with no cast, no trailer, no genres, and no runtime.
    /// Used to snapshot the sparse layout branches in `MovieDetailContentView`.
    static var minimalDetail: MovieDetail {
        MovieDetail(
            id: 1,
            title: "A Film",
            overview: "A short overview with no additional metadata.",
            posterPath: nil,
            backdropPath: nil,
            releaseDate: "2024-06-01",
            voteAverage: 6.5,
            runtimeMinutes: nil,
            genres: [],
            topCast: [],
            trailer: nil
        )
    }

    static var gridSample: [Movie] {
        Array(PreviewMovieCatalog.movies.prefix(4))
    }

    static var fullCatalog: [Movie] {
        PreviewMovieCatalog.movies
    }
}
