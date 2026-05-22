import SwiftUI

/// Search in-flight state for snapshot tests.
struct SearchLoadingSnapshotView: View {
    var body: some View {
        VStack(spacing: CineSpacing.lg) {
            ProgressView()
                .frame(maxWidth: .infinity)
            SearchEmptyStateView()
                .opacity(0.35)
        }
        .padding(.top, CineSpacing.sm)
    }
}
