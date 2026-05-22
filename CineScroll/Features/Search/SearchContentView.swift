import SwiftUI

/// Scrollable body of the search screen: state views, recent chips, and paginated results grid.
struct SearchContentView: View {
    let viewModel: SearchViewModel
    let heroTransitionNamespace: Namespace.ID
    @Binding var searchText: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CineSpacing.lg) {
                if viewModel.displayState == .loading, viewModel.results.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, CineSpacing.sm)
                }

                switch viewModel.displayState {
                case .idleEmptyQuery:
                    SearchEmptyStateView()
                        .cineAccessibility(AccessibilityID.searchEmptyState)
                case .noResults:
                    SearchNoResultsStateView()
                        .cineAccessibility(AccessibilityID.searchNoResultsState)
                case .error(let error) where !error.isConnectivityError:
                    ErrorView(message: error.userFacingMessage) {
                        viewModel.retryLastSearch()
                    }
                default:
                    EmptyView()
                }

                let hidesRecents = !searchText.isEmpty
                    && viewModel.displayState == .results
                    && !viewModel.results.isEmpty
                if !hidesRecents, !viewModel.recentQueries.isEmpty {
                    SearchRecentsRow(queries: viewModel.recentQueries) { query in
                        viewModel.runQueryNow(query)
                        searchText = query
                    }
                    .padding(.horizontal, CineSpacing.md)
                }

                if viewModel.displayState == .results, !viewModel.results.isEmpty {
                    Text("All results")
                        .font(.headline)
                        .padding(.horizontal, CineSpacing.md)

                    LazyVGrid(columns: CineGrid.movieColumns, spacing: CineSpacing.md) {
                        ForEach(Array(viewModel.results.enumerated()), id: \.element.id) { index, movie in
                            NavigationLink(value: movie) {
                                MovieCardView(movie: movie)
                            }
                            .accessibilityLabel(movie.title)
                            .cineAccessibility(AccessibilityID.movieCard(movie.id))
                            .cineZoomSource(id: movie.id, in: heroTransitionNamespace)
                            .onTapGesture {
                                viewModel.recordSelection(movie)
                            }
                            .onAppear {
                                viewModel.triggerLoadMoreSearchIfNeeded(currentIndex: index)
                            }
                        }
                    }
                    .padding(.horizontal, CineSpacing.md)
                    .cineAccessibilityRegion(AccessibilityID.searchResultsSection)

                    if viewModel.isLoadingMoreResults {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, CineSpacing.md)
                    }
                }
            }
            .padding(.vertical, CineSpacing.sm)
        }
        .cineAccessibilityRegion(AccessibilityID.searchRoot)
    }
}
