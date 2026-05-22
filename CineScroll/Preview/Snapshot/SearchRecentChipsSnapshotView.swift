import SwiftUI

/// Recent search chips row for snapshot tests. thin wrapper around `SearchRecentsRow`.
struct SearchRecentChipsSnapshotView: View {
    let queries: [String]

    var body: some View {
        SearchRecentsRow(queries: queries, onSelect: { _ in })
            .padding(.horizontal, CineSpacing.md)
    }
}
