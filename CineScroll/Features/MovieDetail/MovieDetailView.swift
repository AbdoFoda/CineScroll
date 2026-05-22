import SwiftUI

/// Full-screen detail with a hero image and structured metadata.
struct MovieDetailView: View {
    @Environment(\.appDependencies) private var dependencies
    @State private var viewModel: MovieDetailViewModel

    init(movie: Movie, repository: MovieRepository) {
        _viewModel = State(initialValue: MovieDetailViewModel(movie: movie, repository: repository))
    }

    init(movieId: Int, repository: MovieRepository) {
        _viewModel = State(initialValue: MovieDetailViewModel(movieId: movieId, repository: repository))
    }

    var body: some View {
        Group {
            switch viewModel.phase {
            case .idle:
                ProgressView("Loading…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .cineAccessibility(AccessibilityID.detailLoading)

            case .loading:
                if let movie = viewModel.initialMovie {
                    movieFallbackView(for: movie, isLoading: true)
                } else {
                    ProgressView("Loading…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .cineAccessibility(AccessibilityID.detailLoading)
                }

            case .loaded(let detail):
                MovieDetailContentView(detail: detail)

            case .error:
                if let movie = viewModel.initialMovie {
                    // Show poster + title as fallback; error is surfaced via the bottom toast.
                    movieFallbackView(for: movie, isLoading: false)
                } else {
                    // No initial data. hard block with retry (deep-link flow).
                    if case .error(let error) = viewModel.phase {
                        ErrorView(message: error.userFacingMessage) {
                            viewModel.retry()
                        }
                    }
                }
            }
        }
        .cineAccessibilityRegion(AccessibilityID.detailRoot)
        .connectivityToast(
            state: viewModel.connectivity,
            onRetry: { viewModel.retry() },
            bottomPadding: CineSpacing.lg,
            isEnabled: viewModel.initialMovie != nil
        )
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
        .task { viewModel.configureConnectivity(monitor: dependencies.networkMonitor) }
    }

    // MARK: - Private

    /// Shows the movie title once loaded; falls back to the initial movie title
    /// while loading or on error; falls back to "Movie" for deep-link flow with no cached data.
    private var navigationTitle: String {
        if case .loaded(let detail) = viewModel.phase { return detail.title }
        return viewModel.initialMovie?.title ?? "Movie"
    }

    @ViewBuilder
    private func movieFallbackView(for movie: Movie, isLoading: Bool) -> some View {
        ScrollView {
            MovieHeroImageView(url: movie.backdropURL(size: .w780) ?? movie.posterURL(size: .w780))

            VStack(alignment: .leading, spacing: CineSpacing.md) {
                Text(movie.title)
                    .font(.title.bold())
                    .accessibilityAddTraits(.isHeader)

                if isLoading {
                    HStack(spacing: CineSpacing.sm) {
                        ProgressView()
                        Text("Loading details…")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .cineAccessibility(AccessibilityID.detailLoading)
                }
            }
            .padding(CineSpacing.lg)
        }
    }
}
