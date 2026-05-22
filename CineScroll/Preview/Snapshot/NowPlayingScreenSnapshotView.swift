import SwiftUI

/// Now Playing screen layout (grid + title chrome) for snapshot tests.
struct NowPlayingScreenSnapshotView: View {
    let movies: [Movie]

    var body: some View {
        VStack(alignment: .leading, spacing: CineSpacing.sm) {
            Text("Now Playing")
                .font(.largeTitle.bold())
                .padding(.horizontal, CineSpacing.lg)
                .padding(.top, CineSpacing.sm)

            MovieGridSnapshotView(movies: movies)
        }
    }
}
