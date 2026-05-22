import Foundation

/// Drives the now-playing grid with pagination, offline resilience, and explicit fetch guarding.
@MainActor
@Observable
final class MovieListViewModel {
    enum PaginationState: Equatable {
        case idle
        case loading
        case loadingMore
        case loaded
        case error(NetworkError)
    }

    private(set) var movies: [Movie] = []
    private(set) var paginationState: PaginationState = .idle
    let connectivity: ConnectivityState

    private let repository: MovieRepository

    private var currentPage: Int = 0
    private var totalPages: Int = 1
    private var isFetchInFlight = false

    private var listTask: Task<Void, Never>?

    init(repository: MovieRepository) {
        self.repository = repository
        let connectivity = ConnectivityState()
        self.connectivity = connectivity
        connectivity.onReconnect = { [weak self] in self?.backgroundRefresh() }
        connectivity.onOffline = { [weak self] in self?.handleOffline() }
    }

    func configureConnectivity(monitor: NetworkMonitor) {
        connectivity.configure(networkMonitor: monitor)
    }

    var showsInitialPlaceholder: Bool {
        paginationState == .loading && movies.isEmpty
    }

    func onAppear() {
        listTask?.cancel()
        listTask = Task { [weak self] in
            await self?.loadInitialIfNeeded()
        }
    }

    func onDisappear() {
        listTask?.cancel()
        listTask = nil
        if paginationState == .loading {
            paginationState = .idle
        }
    }

    /// Explicit user-initiated retry.
    func retry() {
        listTask?.cancel()
        listTask = Task { [weak self] in
            await self?.refreshFromStart(clearExisting: true)
        }
    }

    /// Checks whether the item at `currentIndex` is close enough to the end of the list
    /// to trigger a page fetch, and starts one if all guards pass.
    func triggerLoadMoreIfNeeded(currentIndex: Int) {
        guard currentIndex >= max(movies.count - 4, 0) else { return }
        guard case .loaded = paginationState else { return }
        guard currentPage < totalPages else { return }
        guard !isFetchInFlight else { return }

        listTask = Task { [weak self] in
            await self?.loadNextPage()
        }
    }

    // MARK: - Private

    /// Silent background refresh triggered automatically on reconnect.
    /// Keeps existing movies visible while fetching fresh page-1 data.
    private func backgroundRefresh() {
        guard !isFetchInFlight, !movies.isEmpty else { return }
        listTask?.cancel()
        listTask = Task { [weak self] in
            guard let self, !Task.isCancelled else { return }
            isFetchInFlight = true
            defer { isFetchInFlight = false }
            do {
                let page = try await repository.fetchNowPlaying(page: 1)
                if Task.isCancelled { return }
                movies = page.results
                currentPage = page.page
                totalPages = page.totalPages
                connectivity.reportSuccess()
            } catch {
                // Silently swallow background-refresh errors, the offline toast already informed the user 
            }
        }
    }

    private func handleOffline() {
        if !movies.isEmpty {
            listTask?.cancel()
            listTask = nil
            isFetchInFlight = false
            if paginationState == .loading || paginationState == .loadingMore {
                paginationState = .loaded
            }
            connectivity.markError(.offline)
        } else if paginationState == .loading {
            listTask?.cancel()
            listTask = nil
            isFetchInFlight = false
            listTask = Task { [weak self] in
                await self?.refreshFromStart(clearExisting: false)
            }
        }
    }

    private func loadInitialIfNeeded() async {
        guard movies.isEmpty else { return }
        await refreshFromStart(clearExisting: false)
    }

    private func refreshFromStart(clearExisting: Bool) async {
        if clearExisting {
            movies.removeAll()
            currentPage = 0
            totalPages = 1
        }

        guard !isFetchInFlight else { return }
        isFetchInFlight = true
        defer { isFetchInFlight = false }

        paginationState = .loading

        do {
            let page = try await repository.fetchNowPlaying(page: 1)
            if Task.isCancelled { return }

            movies = page.results
            currentPage = page.page
            totalPages = page.totalPages
            paginationState = .loaded
            connectivity.reportSuccess()
        } catch is CancellationError {
            if paginationState == .loaded { return }
            paginationState = .idle
        } catch let error as NetworkError where error.isConnectivityError {
            connectivity.markError(error)
            paginationState = .loaded
        } catch let error as NetworkError {
            paginationState = .error(error)
        } catch {
            paginationState = .error(.transport(underlyingDescription: error.localizedDescription))
        }
    }

    private func loadNextPage() async {
        guard !isFetchInFlight else { return }
        isFetchInFlight = true
        defer { isFetchInFlight = false }

        paginationState = .loadingMore
        let nextPage = currentPage + 1

        do {
            let page = try await repository.fetchNowPlaying(page: nextPage)
            if Task.isCancelled { return }

            let existing = Set(movies.map(\.id))
            let fresh = page.results.filter { !existing.contains($0.id) }
            movies.append(contentsOf: fresh)
            currentPage = page.page
            totalPages = page.totalPages
            paginationState = .loaded
        } catch is CancellationError {
            paginationState = .loaded
        } catch let error as NetworkError where error.isConnectivityError {
            paginationState = .loaded
            connectivity.markError(error)
        } catch let error as NetworkError {
            paginationState = .error(error)
        } catch {
            paginationState = .error(.transport(underlyingDescription: error.localizedDescription))
        }
    }
}
