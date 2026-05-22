import SwiftUI

/// Hero image displayed at the top of the movie detail screen.
///
/// Renders `url` via `AsyncImageView` at the canonical detail hero height and
/// overlays a bottom-to-top gradient scrim so title text above it remains readable.
/// Extracted to eliminate duplication between `MovieDetailContentView` (loaded state)
/// and `MovieDetailView.movieFallbackView` (loading / offline fallback state).
struct MovieHeroImageView: View {
    let url: URL?

    var body: some View {
        AsyncImageView(url: url, contentMode: .fill)
            .frame(maxWidth: .infinity, minHeight: CineSize.detailHeroHeight, maxHeight: CineSize.detailHeroHeight)
            .clipped()
            .overlay(alignment: .bottom) {
                LinearGradient(
                    colors: [.black.opacity(CineOpacity.heroScrim), .clear],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .frame(height: CineSize.detailHeroGradientHeight)
            }
    }
}
