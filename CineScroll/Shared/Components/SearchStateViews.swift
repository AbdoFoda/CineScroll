import SwiftUI

/// Empty search field state (extracted for snapshots and reuse).
struct SearchEmptyStateView: View {
    var body: some View {
        ContentUnavailableView(
            "Search movies",
            systemImage: "magnifyingglass",
            description: Text("Start typing for autocomplete suggestions from TMDB.")
        )
        .frame(maxWidth: .infinity)
    }
}

/// No TMDB matches for the current query.
struct SearchNoResultsStateView: View {
    var body: some View {
        ContentUnavailableView(
            "No matches",
            systemImage: "film",
            description: Text("Try a different spelling or a broader query.")
        )
        .frame(maxWidth: .infinity)
    }
}
