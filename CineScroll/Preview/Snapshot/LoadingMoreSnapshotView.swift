import SwiftUI

/// Pagination footer on the now-playing grid (snapshot tests).
struct LoadingMoreSnapshotView: View {
    var body: some View {
        ProgressView()
            .padding(CineSpacing.lg)
            .background(.thinMaterial, in: Capsule())
    }
}
