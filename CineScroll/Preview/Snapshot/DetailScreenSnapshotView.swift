import SwiftUI

/// Detail screen chrome for snapshots (no `NavigationStack`. avoids OS-specific nav bar drift).
struct DetailScreenSnapshotView: View {
    let detail: MovieDetail

    var body: some View {
        VStack(spacing: 0) {
            Text("Details")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, CineSpacing.sm)
                .background(.bar)

            MovieDetailContentView(detail: detail)
        }
    }
}
