import SwiftUI

/// Shell: owns the view model, wires searchable/submit, hosts the content + connectivity toast.
struct SearchView: View {
    @Environment(\.appDependencies) private var dependencies
    @Binding private var navigationPath: NavigationPath
    private let heroTransitionNamespace: Namespace.ID

    @State private var searchText = ""
    @State private var viewModel: SearchViewModel

    init(
        repository: MovieRepository,
        recentStore: RecentSearchStoring,
        navigationPath: Binding<NavigationPath>,
        heroTransitionNamespace: Namespace.ID,
        debounceDelay: Duration = .milliseconds(300)
    ) {
        self.heroTransitionNamespace = heroTransitionNamespace
        _navigationPath = navigationPath
        _viewModel = State(
            initialValue: SearchViewModel(
                repository: repository,
                recentStore: recentStore,
                debounceDelay: debounceDelay
            )
        )
    }

    var body: some View {
        SearchContentView(
            viewModel: viewModel,
            heroTransitionNamespace: heroTransitionNamespace,
            searchText: $searchText
        )
        .connectivityToast(
            state: viewModel.connectivity,
            onRetry: { viewModel.retryLastSearch() }
        )
        .navigationTitle("Search")
        .searchable(text: $searchText, prompt: "Movies")
        .accessibilityIdentifier(AccessibilityID.searchField)
        .searchSuggestions { autocompleteSuggestions }
        .onChange(of: searchText) { _, newValue in viewModel.searchTextChanged(newValue) }
        .onSubmit(of: .search) {
            viewModel.commitSearch(searchText)
            viewModel.runQueryNow(searchText)
        }
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
        .task { viewModel.configureConnectivity(monitor: dependencies.networkMonitor) }
    }

    @ViewBuilder
    private var autocompleteSuggestions: some View {
        let recents = viewModel.matchingRecents(for: searchText)
        if !recents.isEmpty {
            Section("Recent") {
                ForEach(recents, id: \.self) { query in
                    Text(query).searchCompletion(query)
                }
            }
        }

        if viewModel.displayState == .loading,
           !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Text("Searching…").foregroundStyle(.secondary)
        }

        if !viewModel.autocompleteMovies.isEmpty {
            Section("Movies") {
                ForEach(viewModel.autocompleteMovies) { movie in
                    Button {
                        viewModel.recordSelection(movie)
                        navigationPath.append(movie)
                    } label: {
                        SearchSuggestionRow(movie: movie)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var path = NavigationPath()
    @Previewable @Namespace var heroTransitionNamespace
    let repository = PreviewMovieRepository()
    return NavigationStack(path: $path) {
        SearchView(
            repository: repository,
            recentStore: InMemoryRecentSearchStore(),
            navigationPath: $path,
            heroTransitionNamespace: heroTransitionNamespace
        )
        .navigationDestination(for: Movie.self) { movie in
            MovieDetailView(movie: movie, repository: repository)
        }
    }
    .environment(\.appDependencies, .preview())
}
