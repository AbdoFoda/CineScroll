import SwiftUI

/// Root tab shell wiring navigation stacks, deep links, and dependency injection.
struct RootView: View {
    @Environment(\.appDependencies) private var dependencies

    @Namespace private var heroTransitionNamespace
    @State private var selectedTab: Tab = .nowPlaying
    @State private var homePath = NavigationPath()
    @State private var searchPath = NavigationPath()

    private enum Tab: Hashable {
        case nowPlaying
        case search
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack(path: $homePath) {
                MovieListView(
                    repository: dependencies.movieRepository,
                    heroTransitionNamespace: heroTransitionNamespace
                )
                .navigationDestination(for: Movie.self) { movie in
                    MovieDetailView(movie: movie, repository: dependencies.movieRepository)
                }
                .navigationDestination(for: Int.self) { id in
                    MovieDetailView(movieId: id, repository: dependencies.movieRepository)
                }
            }
            .tabItem { Label("Now Playing", systemImage: "film") }
            .tag(Tab.nowPlaying)
            .cineAccessibility(AccessibilityID.tabNowPlaying)

            NavigationStack(path: $searchPath) {
                SearchView(
                    repository: dependencies.movieRepository,
                    recentStore: dependencies.recentSearchStore,
                    navigationPath: $searchPath,
                    heroTransitionNamespace: heroTransitionNamespace,
                    debounceDelay: dependencies.searchDebounceDelay
                )
                .navigationDestination(for: Movie.self) { movie in
                    MovieDetailView(movie: movie, repository: dependencies.movieRepository)
                }
                .navigationDestination(for: Int.self) { id in
                    MovieDetailView(movieId: id, repository: dependencies.movieRepository)
                }
            }
            .tabItem { Label("Search", systemImage: "magnifyingglass") }
            .tag(Tab.search)
            .cineAccessibility(AccessibilityID.tabSearch)
        }
        .cineAccessibility(AccessibilityID.rootTabView)
        .onOpenURL { url in
            guard let id = DeepLinkParser.movieID(from: url) else { return }
            selectedTab = .nowPlaying
            homePath = NavigationPath()
            homePath.append(id)
        }
    }
}
