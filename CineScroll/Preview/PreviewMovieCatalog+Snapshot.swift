import Foundation

extension PreviewMovieCatalog {
    /// Rich detail fixture for snapshots and previews.
    static var matrixDetail: MovieDetail {
        guard let movie = movies.first(where: { $0.id == 101 }) else {
            fatalError("Preview catalog must include The Matrix (id 101)")
        }
        return MovieDetail(
            id: movie.id,
            title: movie.title,
            overview: movie.overview,
            posterPath: movie.posterPath,
            backdropPath: movie.backdropPath,
            releaseDate: movie.releaseDate,
            voteAverage: movie.voteAverage,
            runtimeMinutes: 136,
            genres: [
                Genre(id: 28, name: "Action"),
                Genre(id: 878, name: "Science Fiction"),
            ],
            topCast: [
                CastMember(id: 6384,  name: "Keanu Reeves",       profilePath: "/4D0PpNI0kmP58hgrwGC3wCjxhnm.jpg"),
                CastMember(id: 2975,  name: "Laurence Fishburne", profilePath: "/mh0lZ1XsT84FayMNiT6Erh91mVu.jpg"),
                CastMember(id: 70851, name: "Carrie-Anne Moss",   profilePath: "/8iATAc5z5XOeZMjkFKIQQBHKoq1.jpg"),
                CastMember(id: 1331,  name: "Hugo Weaving",       profilePath: "/dQxPteXAjOT1Zjik1dHEP80cFU4.jpg"),
            ],
            trailer: TrailerInfo(youtubeKey: "m8e-FF8MsqU")
        )
    }
}
