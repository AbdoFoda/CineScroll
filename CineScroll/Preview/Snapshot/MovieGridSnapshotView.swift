import SwiftUI

/// Two-column movie grid for snapshots (deterministic catalog subset).
struct MovieGridSnapshotView: View {
    let movies: [Movie]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: CineGrid.movieColumns, spacing: CineSpacing.md) {
                ForEach(movies) { movie in
                    MovieCardView(movie: movie)
                }
            }
            .padding(CineSpacing.md)
        }
    }
}
