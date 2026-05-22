import SwiftUI

/// Detail error state for snapshot tests.
struct MovieDetailErrorSnapshotView: View {
    var body: some View {
        ErrorView(message: "Could not load movie details.") {}
    }
}
