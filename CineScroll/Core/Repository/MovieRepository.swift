import Foundation

/// Fetches TMDB movie lists, detail, and search results.
protocol MovieRepository: Sendable {
    /// Returns a page of currently playing movies.
    func fetchNowPlaying(page: Int) async throws -> PagedResponse<Movie>

    /// Returns merged detail and credits for a movie id.
    func fetchMovieDetail(id: Int) async throws -> MovieDetail

    /// Returns a page of search hits for the given query.
    func searchMovies(query: String, page: Int) async throws -> PagedResponse<Movie>
}
