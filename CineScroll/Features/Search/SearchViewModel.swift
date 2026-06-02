import Foundation

/// Debounced TMDB autocomplete/search with explicit cancellation of in-flight fetches
/// and infinite-scroll pagination for search results.
@MainActor
@Observable
final class SearchViewModel {

    enum DisplayState: Equatable {
        case idleEmptyQuery
        case loading
        case results
        case noResults
        case error(NetworkError)
    }

    private(set) var results: [Movie] = []
    private(set) var displayState: DisplayState = .idleEmptyQuery
    private(set) var recentQueries: [String]
    private(set) var lastQuery: String = ""
    private(set) var isLoadingMoreResults: Bool = false
    let connectivity: ConnectivityState

    private let repository: MovieRepository
    private let recentStore: RecentSearchStoring
    private let debounceDelay: Duration

    private var debounceTask: Task<Void, Never>?
    private var fetchTask: Task<Void, Never>?
    private var loadRecentsTask: Task<Void, Never>?
    /// Skips one debounced empty query after `runQueryNow` (avoids canceling chip/submit searches).
    private var skipNextEmptyDebounce = false

    // Search pagination
    private var searchCurrentPage: Int = 0
    private var searchTotalPages: Int = 1
    private var isSearchFetchInFlight = false

    init(
        repository: MovieRepository,
        recentStore: RecentSearchStoring,
        debounceDelay: Duration = .milliseconds(300)
    ) {
        self.repository = repository
        self.recentStore = recentStore
        self.debounceDelay = debounceDelay
        recentQueries = []
        let connectivity = ConnectivityState()
        self.connectivity = connectivity
        connectivity.onReconnect = { [weak self] in self?.retryLastSearch() }
        connectivity.onOffline = { [weak self] in self?.handleOffline() }
    }

    func configureConnectivity(monitor: NetworkMonitor) {
        connectivity.configure(networkMonitor: monitor)
    }

    /// Reloads recents from persistence when the UI appears.
    func onAppear() {
        loadRecentsTask?.cancel()
        loadRecentsTask = Task { [weak self] in
            await self?.reloadRecentQueriesFromStore()
        }
    }

    /// Loads persisted recent searches into `recentQueries`.
    func reloadRecentQueriesFromStore() async {
        recentQueries = await recentStore.loadQueries()
    }

    /// Waits for the `Task` started by the most recent `onAppear()`. Used by unit tests (`@testable`).
    func awaitOnAppearRecentsLoad() async {
        await loadRecentsTask?.value
    }

    /// Cancels background work when the search UI goes away.
    func onDisappear() {
        debounceTask?.cancel()
        debounceTask = nil
        fetchTask?.cancel()
        fetchTask = nil
        loadRecentsTask?.cancel()
        loadRecentsTask = nil
    }

    /// TMDB titles for the native autocomplete suggestion list (subset of `results`).
    var autocompleteMovies: [Movie] {
        Array(results.prefix(MoviePresentationConfig.autocompleteLimit))
    }

    /// Recent queries filtered for autocomplete (prefix match, or all when query is empty).
    func matchingRecents(for query: String) -> [String] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return recentQueries }
        return recentQueries.filter { $0.localizedCaseInsensitiveContains(trimmed) }
    }

    /// Persists a recent query when the user submits search or picks a suggestion.
    /// `recentQueries` is updated synchronously so callers can read the new value immediately;
    /// store persistence is dispatched asynchronously.
    func commitSearch(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        recentQueries = buildRecentsList(appending: trimmed)
        let snapshot = recentQueries
        Task { [weak self] in await self?.recentStore.saveQueries(snapshot) }
    }

    /// Records a movie title in recents after the user opens it from autocomplete.
    func recordSelection(_ movie: Movie) {
        Task { [weak self] in await self?.persistRecent(movie.title) }
    }

    /// Called from the view whenever the search field changes.
    func searchTextChanged(_ text: String) {
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await Task.sleep(for: debounceDelay)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            await self.handleDebouncedQuery(text)
        }
    }

    /// Runs a query immediately (used by submit and recent chips).
    /// - Parameter saveToRecents: When true, persists the query after a completed search.
    func runQueryNow(_ text: String, saveToRecents: Bool = true) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        skipNextEmptyDebounce = !trimmed.isEmpty
        debounceTask?.cancel()
        debounceTask = nil
        fetchTask?.cancel()
        fetchTask = Task { [weak self] in
            guard let self else { return }
            await performSearch(trimmed)
            guard saveToRecents, !trimmed.isEmpty else { return }
            switch displayState {
            case .results, .noResults:
                await persistRecent(trimmed)
            default:
                break
            }
        }
    }

    /// Checks whether the item at `currentIndex` is close enough to the end to trigger
    /// loading the next search page. Called synchronously from `.onAppear` in the view.
    ///
    /// **Important**: do NOT cancel `fetchTask` here. see `MovieListViewModel` for the
    /// full explanation of the FIFO-task/isFetchInFlight race. `isSearchFetchInFlight`
    /// is the sole deduplication guard.
    func triggerLoadMoreSearchIfNeeded(currentIndex: Int) {
        guard displayState == .results else { return }
        guard currentIndex >= max(results.count - 4, 0) else { return }
        guard searchCurrentPage < searchTotalPages else { return }
        guard !isSearchFetchInFlight else { return }

        fetchTask = Task { [weak self] in
            await self?.loadNextSearchPage()
        }
    }

    /// Re-runs the last attempted query. used after reconnection.
    func retryLastSearch() {
        guard !lastQuery.isEmpty else { return }
        runQueryNow(lastQuery)
    }

    // MARK: - Private
    private func handleOffline() {
        if !results.isEmpty {
            fetchTask?.cancel()
            fetchTask = nil
            displayState = .results
            connectivity.markError(.offline)
        } else if displayState == .loading {
            debounceTask?.cancel()
            debounceTask = nil
            fetchTask?.cancel()
            fetchTask = nil
            displayState = .idleEmptyQuery
            connectivity.markError(.offline)
        }
    }

    private func handleDebouncedQuery(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            if skipNextEmptyDebounce {
                skipNextEmptyDebounce = false
                return
            }
            fetchTask?.cancel()
            fetchTask = nil
            results = []
            lastQuery = ""
            searchCurrentPage = 0
            searchTotalPages = 1
            displayState = .idleEmptyQuery
            return
        }
        skipNextEmptyDebounce = false

        fetchTask?.cancel()
        fetchTask = Task { [weak self] in
            await self?.performSearch(trimmed)
        }
    }

    private func performSearch(_ trimmed: String) async {
        guard !trimmed.isEmpty else {
            results = []
            lastQuery = ""
            searchCurrentPage = 0
            searchTotalPages = 1
            displayState = .idleEmptyQuery
            return
        }

        lastQuery = trimmed
        displayState = .loading
        let previousResults = results
        results = []
        searchCurrentPage = 0
        searchTotalPages = 1
        isSearchFetchInFlight = true
        defer { isSearchFetchInFlight = false }

        do {
            let page = try await repository.searchMovies(query: trimmed, page: 1)
            if Task.isCancelled { return }

            results = page.results
            searchCurrentPage = page.page
            searchTotalPages = page.totalPages
            connectivity.reportSuccess()
            displayState = results.isEmpty ? .noResults : .results
        } catch is CancellationError {
            return
        } catch let error as NetworkError where error.isConnectivityError {
            connectivity.markError(error)
            results = previousResults
            displayState = results.isEmpty ? .idleEmptyQuery : .results
        } catch let error as NetworkError {
            displayState = .error(error)
        } catch {
            displayState = .error(.transport(underlyingDescription: error.localizedDescription))
        }
    }

    private func loadNextSearchPage() async {
        guard !isSearchFetchInFlight, !lastQuery.isEmpty else { return }
        isSearchFetchInFlight = true
        isLoadingMoreResults = true
        defer {
            isSearchFetchInFlight = false
            isLoadingMoreResults = false
        }

        let nextPage = searchCurrentPage + 1
        do {
            let page = try await repository.searchMovies(query: lastQuery, page: nextPage)
            if Task.isCancelled { return }

            let existing = Set(results.map(\.id))
            let fresh = page.results.filter { !existing.contains($0.id) }
            results.append(contentsOf: fresh)
            searchCurrentPage = page.page
            searchTotalPages = page.totalPages
        } catch is CancellationError {
            return
        } catch let error as NetworkError where error.isConnectivityError {
            connectivity.markError(error)
        } catch {
            // Silently ignore pagination errors. user still sees existing results.
        }
    }

    private func persistRecent(_ trimmed: String) async {
        recentQueries = buildRecentsList(appending: trimmed)
        await recentStore.saveQueries(recentQueries)
    }

    /// Builds the deduped, capped recents list with `trimmed` inserted at the front.
    private func buildRecentsList(appending trimmed: String) -> [String] {
        var items = recentQueries.filter { $0.caseInsensitiveCompare(trimmed) != .orderedSame }
        items.insert(trimmed, at: 0)
        return Array(items.prefix(MoviePresentationConfig.recentSearchesLimit))
    }
}
