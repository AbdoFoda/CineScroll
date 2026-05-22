import SwiftUI
@testable import CineScroll

@MainActor
final class SearchSnapshotsTests: SnapshotTestCase {
  func testSearchEmptyState() {
    assertCineColorSchemeSnapshots(
      of: SearchEmptyStateView(),
      size: SnapshotSize.searchPanel
    )
  }

  func testSearchNoResultsState() {
    assertCineColorSchemeSnapshots(
      of: SearchNoResultsStateView(),
      size: SnapshotSize.searchPanel
    )
  }

  func testSearchLoadingState() {
    assertCineColorSchemeSnapshots(
      of: SearchLoadingSnapshotView(),
      size: SnapshotSize.searchLoading
    )
  }

  func testSearchResultsGrid() {
    assertCineColorSchemeSnapshots(
      of: SearchResultsSnapshotView(movies: PreviewSnapshotFixtures.gridSample),
      size: SnapshotSize.gridPanel
    )
  }

  func testSearchRecentChips() {
    assertCineColorSchemeSnapshots(
      of: SearchRecentChipsSnapshotView(queries: ["Matrix", "Inception", "Interstellar"]),
      size: SnapshotSize.recentChips
    )
  }

  // Full cap of 10 queries. verifies horizontal scroll handles overflow without clipping.
  func testSearchRecentChipsManyQueries() {
    let queries = ["Matrix", "Inception", "Interstellar", "Dark Knight", "Dune",
                   "Oppenheimer", "Parasite", "Tenet", "Arrival", "Her"]
    assertCineColorSchemeSnapshots(
      of: SearchRecentChipsSnapshotView(queries: queries),
      size: SnapshotSize.recentChips
    )
  }

  func testSearchRecentChipsEmpty() {
    assertCineColorSchemeSnapshots(
      of: SearchRecentChipsSnapshotView(queries: []),
      size: SnapshotSize.recentChips
    )
  }
}
