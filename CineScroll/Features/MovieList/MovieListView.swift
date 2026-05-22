import SwiftUI

/// Primary grid of currently playing movies with infinite scrolling.
struct MovieListView: View {
    @Environment(\.appDependencies) private var dependencies
    private let heroTransitionNamespace: Namespace.ID

    @State private var viewModel: MovieListViewModel

    init(repository: MovieRepository, heroTransitionNamespace: Namespace.ID) {
        self.heroTransitionNamespace = heroTransitionNamespace
        _viewModel = State(initialValue: MovieListViewModel(repository: repository))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                LazyVGrid(columns: CineGrid.movieColumns, spacing: CineSpacing.md) {
                    if viewModel.showsInitialPlaceholder {
                        ForEach(0 ..< CineSize.initialPlaceholderCardCount, id: \.self) { _ in
                            MovieCardPlaceholder()
                        }
                    } else {
                        ForEach(Array(viewModel.movies.enumerated()), id: \.element.id) { index, movie in
                            NavigationLink(value: movie) {
                                MovieCardView(movie: movie)
                            }
                            .accessibilityLabel(movie.title)
                            .cineAccessibility(AccessibilityID.movieCard(movie.id))
                            .cineZoomSource(id: movie.id, in: heroTransitionNamespace)
                            .onAppear {
                                viewModel.triggerLoadMoreIfNeeded(currentIndex: index)
                            }
                        }
                    }
                }
                .padding(.horizontal, CineSpacing.md)
                .padding(.vertical, CineSpacing.sm)
            }
            .cineAccessibilityRegion(AccessibilityID.nowPlayingGrid)

            // Full-screen error only for hard (non-connectivity) errors when there are no movies.
            if case let .error(error) = viewModel.paginationState, !error.isConnectivityError {
                ErrorView(message: error.userFacingMessage) {
                    viewModel.retry()
                }
                .background(.ultraThinMaterial)
            }

            // Loading-more indicator; sits above the connectivity toast when both are visible.
            let toastActive = viewModel.connectivity.connectivityError != nil || viewModel.connectivity.isBackOnline
            if viewModel.paginationState == .loadingMore {
                ProgressView()
                    .padding(CineSpacing.lg)
                    .background(.thinMaterial, in: Capsule())
                    .padding(.bottom, toastActive ? 70 : CineSpacing.md)
                    .cineAccessibility(AccessibilityID.nowPlayingLoadingMore)
            }
        }
        .connectivityToast(
            state: viewModel.connectivity,
            onRetry: { viewModel.retry() },
            bottomPadding: viewModel.paginationState == .loadingMore ? CineSpacing.xl : CineSpacing.md
        )
        .navigationTitle("Now Playing")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
        .task { viewModel.configureConnectivity(monitor: dependencies.networkMonitor) }
    }
}
