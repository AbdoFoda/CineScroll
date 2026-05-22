import SwiftUI
@testable import CineScroll

@MainActor
final class ScreenSnapshotsTests: SnapshotTestCase {
  func testDetailScreenWithNavigation() {
    assertCineColorSchemeSnapshots(
      of: DetailScreenSnapshotView(detail: PreviewSnapshotFixtures.matrixDetail),
      size: SnapshotSize.detailPanel
    )
  }

  func testSearchScreenEmpty() {
    assertCineColorSchemeSnapshots(
      of: SearchScreenSnapshotView {
        SearchEmptyStateView()
      },
      size: SnapshotSize.searchPanel
    )
  }

  func testSearchScreenNoResults() {
    assertCineColorSchemeSnapshots(
      of: SearchScreenSnapshotView {
        SearchNoResultsStateView()
      },
      size: SnapshotSize.searchPanel
    )
  }

  func testSearchScreenResults() {
    assertCineColorSchemeSnapshots(
      of: SearchScreenSnapshotView {
        SearchResultsSnapshotView(movies: PreviewSnapshotFixtures.gridSample)
      },
      size: SnapshotSize.gridPanel
    )
  }

  // Chips visible above the idle empty state. the most common first-open state.
  func testSearchScreenWithRecentChips() {
    let queries = ["Matrix", "Inception", "Dark Knight"]
    assertCineColorSchemeSnapshots(
      of: SearchScreenSnapshotView {
        VStack(alignment: .leading, spacing: 0) {
          SearchRecentChipsSnapshotView(queries: queries)
          SearchEmptyStateView()
        }
      },
      size: SnapshotSize.searchPanel
    )
  }
}
