import Foundation

/// Loads and presents a single movie detail screen.
@MainActor
@Observable
final class MovieDetailViewModel {
    enum Phase: Equatable {
        case idle
        case loading
        case loaded(MovieDetail)
        case error(NetworkError)
    }

    private(set) var phase: Phase = .idle
    /// Always-available summary from the navigation source. Used to show the poster
    /// and title immediately while loading, and as a fallback when offline.
    let initialMovie: Movie?
    let connectivity: ConnectivityState

    private let movieID: Int
    private let repository: MovieRepository
    private var loadTask: Task<Void, Never>?
    /// True while an explicit user-initiated retry is in flight. Prevents transient
    /// connectivity events from cancelling a task the user deliberately started.
    private var isManualRetry = false

    /// Preferred init: receives the full `Movie` from the navigation grid.
    init(movie: Movie, repository: MovieRepository) {
        self.movieID = movie.id
        self.initialMovie = movie
        self.repository = repository
        self.connectivity = ConnectivityState()
        wireConnectivity()
    }

    /// Fallback init for deep-link navigation where only the `id` is available.
    init(movieId: Int, repository: MovieRepository) {
        self.movieID = movieId
        self.initialMovie = nil
        self.repository = repository
        self.connectivity = ConnectivityState()
        wireConnectivity()
    }

    func configureConnectivity(monitor: NetworkMonitor) {
        connectivity.configure(networkMonitor: monitor)
    }

    func onAppear() {
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            await self?.load()
        }
    }

    func onDisappear() {
        loadTask?.cancel()
        loadTask = nil
    }

    func retry() {
        isManualRetry = true
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            await self?.load()
        }
    }

    // MARK: - Private

    private func wireConnectivity() {
        connectivity.onReconnect = { [weak self] in
            guard let self, case .error = phase else { return }
            retry()
        }
        connectivity.onOffline = { [weak self] in self?.handleOffline() }
    }

    private func handleOffline() {
        guard case .loading = phase, !isManualRetry else { return }
        loadTask?.cancel()
        loadTask = nil
        phase = .error(.offline)
        connectivity.markError(.offline)
    }

    private func load() async {
        defer { isManualRetry = false }
        phase = .loading
        do {
            let detail = try await repository.fetchMovieDetail(id: movieID)
            if Task.isCancelled { return }
            phase = .loaded(detail)
            connectivity.reportSuccess()
        } catch is CancellationError {
            // handleOffline() may have already set .error(.offline) before cancelling;
            // preserve that phase rather than resetting to .idle.
            if case .error = phase { return }
            phase = .idle
        } catch let error as NetworkError {
            phase = .error(error)
            if error.isConnectivityError {
                connectivity.markError(error)
            }
        } catch {
            phase = .error(.transport(underlyingDescription: error.localizedDescription))
        }
    }
}
