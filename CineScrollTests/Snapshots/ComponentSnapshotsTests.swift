import SwiftUI
@testable import CineScroll

@MainActor
final class ComponentSnapshotsTests: SnapshotTestCase {
  func testMovieCard() {
    assertCineColorSchemeSnapshots(
      of: MovieCardView(movie: PreviewSnapshotFixtures.matrix),
      size: SnapshotSize.movieCard
    )
  }

  func testMovieCardPlaceholder() {
    assertCineColorSchemeSnapshots(
      of: MovieCardPlaceholder(),
      size: SnapshotSize.movieCard
    )
  }

  func testSearchSuggestionRow() {
    assertCineColorSchemeSnapshots(
      of: SearchSuggestionRow(movie: PreviewSnapshotFixtures.inception),
      size: SnapshotSize.suggestionRow
    )
  }

  func testErrorViewWithRetry() {
    assertCineColorSchemeSnapshots(
      of: ErrorView(message: "Could not reach the server.") {},
      size: SnapshotSize.errorPanel
    )
  }

  func testErrorViewWithoutRetry() {
    assertCineColorSchemeSnapshots(
      of: ErrorView(message: "Set CINESCROLL_API_BASE_URL in Config/Secrets.xcconfig.", onRetry: nil),
      size: SnapshotSize.errorPanel
    )
  }

  func testLoadingMoreIndicator() {
    assertCineColorSchemeSnapshots(
      of: LoadingMoreSnapshotView(),
      size: SnapshotSize.loadingMore
    )
  }

  func testCastCarousel() {
    assertCineColorSchemeSnapshots(
      of: CastCarouselView(cast: PreviewSnapshotFixtures.matrixDetail.topCast)
        .background(Color(.systemBackground)),
      size: SnapshotSize.castCarousel
    )
  }

  func testTrailerCard() {
    let trailer = TrailerInfo(youtubeKey: "m8e-FF8MsqU")
    assertCineColorSchemeSnapshots(
      of: TrailerCardView(trailer: trailer)
        .padding(CineSpacing.md)
        .background(Color(.systemBackground)),
      size: SnapshotSize.trailerCard
    )
  }

  func testNetworkStatusBannerOffline() {
    assertCineColorSchemeSnapshots(
      of: bannerContainer(NetworkStatusBanner(isConnected: false, onReload: {})),
      size: SnapshotSize.networkBanner
    )
  }

  func testNetworkStatusBannerOfflineNoReload() {
    assertCineColorSchemeSnapshots(
      of: bannerContainer(NetworkStatusBanner(isConnected: false)),
      size: SnapshotSize.networkBanner
    )
  }

  private func bannerContainer<V: View>(_ banner: V) -> some View {
    VStack(spacing: 0) {
      banner
      Spacer()
    }
    .background(Color(.systemBackground))
  }
}

private extension SnapshotSize {
  static let castCarousel = CGSize(width: 393, height: 150)
  static let trailerCard  = CGSize(width: 393, height: 260)
  static let networkBanner = CGSize(width: 393, height: 60)
}
