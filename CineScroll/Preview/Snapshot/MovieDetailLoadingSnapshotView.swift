import SwiftUI

/// Detail loading state for snapshot tests.
struct MovieDetailLoadingSnapshotView: View {
    var body: some View {
        ProgressView("Loading…")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
