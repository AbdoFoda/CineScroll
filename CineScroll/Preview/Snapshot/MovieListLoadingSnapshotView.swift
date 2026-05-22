import SwiftUI

/// Initial loading placeholders for the now-playing grid (snapshot tests).
struct MovieListLoadingSnapshotView: View {
    var body: some View {
        LazyVGrid(columns: CineGrid.movieColumns, spacing: CineSpacing.md) {
            ForEach(0 ..< CineSize.initialPlaceholderCardCount, id: \.self) { _ in
                MovieCardPlaceholder()
            }
        }
        .padding(CineSpacing.md)
    }
}
