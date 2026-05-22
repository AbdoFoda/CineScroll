import SwiftUI

/// Search tab shell for snapshots (deterministic chrome without `NavigationStack`).
struct SearchScreenSnapshotView<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            Text("Search")
                .font(.largeTitle.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, CineSpacing.lg)
                .padding(.vertical, CineSpacing.sm)

            ScrollView {
                content()
                    .padding(.vertical, CineSpacing.sm)
            }
        }
    }
}
