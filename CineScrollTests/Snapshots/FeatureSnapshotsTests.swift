import SwiftUI
@testable import CineScroll

@MainActor
final class FeatureSnapshotsTests: SnapshotTestCase {
  func testMovieDetailContent() {
    assertCineColorSchemeSnapshots(
      of: MovieDetailContentView(detail: PreviewSnapshotFixtures.matrixDetail),
      size: SnapshotSize.detailPanel
    )
  }

  func testMovieDetailContentMinimal() {
    assertCineColorSchemeSnapshots(
      of: MovieDetailContentView(detail: PreviewSnapshotFixtures.minimalDetail),
      size: SnapshotSize.detailPanel
    )
  }

  func testMovieDetailLoading() {
    assertCineColorSchemeSnapshots(
      of: MovieDetailLoadingSnapshotView(),
      size: SnapshotSize.detailLoading
    )
  }

  func testMovieDetailError() {
    assertCineColorSchemeSnapshots(
      of: MovieDetailErrorSnapshotView(),
      size: SnapshotSize.errorPanel
    )
  }

  func testMovieGrid() {
    assertCineColorSchemeSnapshots(
      of: MovieGridSnapshotView(movies: PreviewSnapshotFixtures.gridSample),
      size: SnapshotSize.gridPanel
    )
  }

  func testMovieGridFullCatalog() {
    assertCineColorSchemeSnapshots(
      of: MovieGridSnapshotView(movies: PreviewSnapshotFixtures.fullCatalog),
      size: SnapshotSize.fullGridPanel
    )
  }

  func testMovieGridIPadWidth() {
    assertCineColorSchemeSnapshots(
      of: MovieGridSnapshotView(movies: PreviewSnapshotFixtures.fullCatalog),
      size: SnapshotSize.iPadGrid
    )
  }

  func testMovieListLoadingPlaceholders() {
    assertCineColorSchemeSnapshots(
      of: MovieListLoadingSnapshotView(),
      size: SnapshotSize.loadingGrid
    )
  }

  func testNowPlayingScreen() {
    assertCineColorSchemeSnapshots(
      of: NowPlayingScreenSnapshotView(movies: PreviewSnapshotFixtures.gridSample),
      size: SnapshotSize.nowPlayingScreen
    )
  }
}

private extension SnapshotSize {
  static let iPadGrid = CGSize(width: 744, height: 780)
}
