import SwiftUI

/// Search results grid for snapshot tests.
struct SearchResultsSnapshotView: View {
    let movies: [Movie]

    var body: some View {
        VStack(alignment: .leading, spacing: CineSpacing.md) {
            Text("All results")
                .font(.headline)
                .padding(.horizontal, CineSpacing.md)

            LazyVGrid(columns: CineGrid.movieColumns, spacing: CineSpacing.md) {
                ForEach(movies) { movie in
                    MovieCardView(movie: movie)
                }
            }
            .padding(.horizontal, CineSpacing.md)
        }
    }
}
