import SwiftUI

/// Loaded movie detail body
struct MovieDetailContentView: View {
    let detail: MovieDetail

    var body: some View {
        ScrollView {
            heroImage

            VStack(alignment: .leading, spacing: CineSpacing.md) {
                Text(detail.title)
                    .font(.title.bold())
                    .accessibilityAddTraits(.isHeader)

                metaRow

                if !detail.genresLine.isEmpty {
                    Text(detail.genresLine)
                        .font(.subheadline)
                }

                Text(detail.overview)
                    .font(.body)

                if let trailer = detail.trailer {
                    trailerSection(trailer)
                }
            }
            .padding(CineSpacing.lg)

            if !detail.topCast.isEmpty {
                CastCarouselView(cast: detail.topCast)
                    .padding(.bottom, CineSpacing.xl)
            }
        }
    }

    // MARK: - Sub-views

    private var heroImage: some View {
        MovieHeroImageView(url: detail.backdropURL(size: .w780) ?? detail.posterURL(size: .w780))
    }

    private var metaRow: some View {
        HStack(spacing: CineSpacing.md) {
            Text(detail.formattedRating)
            if let release = detail.formattedReleaseDate {
                Text(release)
            }
            if let runtime = detail.formattedRuntime {
                Text(runtime)
            }
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }

    private func trailerSection(_ trailer: TrailerInfo) -> some View {
        VStack(alignment: .leading, spacing: CineSpacing.sm) {
            Text("Trailer")
                .font(.title3.bold())
            TrailerCardView(trailer: trailer)
        }
        .padding(.top, CineSpacing.xs)
    }
}
