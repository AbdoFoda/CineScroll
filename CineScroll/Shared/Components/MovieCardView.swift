import SwiftUI

/// Poster-forward card used in grids and search results.
struct MovieCardView: View {
    let movie: Movie

    var body: some View {
        VStack(alignment: .leading, spacing: CineSpacing.sm) {
            AsyncImageView(url: movie.posterURL())
                .frame(maxWidth: .infinity)
                .aspectRatio(
                    CineSize.posterAspectWidth / CineSize.posterAspectHeight,
                    contentMode: .fill
                )
                .clipShape(RoundedRectangle(cornerRadius: CineRadius.md, style: .continuous))

            Text(movie.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .frame(minHeight: CineSize.movieCardTitleMinHeight, alignment: .topLeading)

            Text(movie.formattedReleaseDate ?? "")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(CineSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: CineRadius.lg, style: .continuous)
                .fill(.thinMaterial)
        )
    }
}

/// Skeleton placeholder used for the initial grid load.
struct MovieCardPlaceholder: View {
    var body: some View {
        MovieCardView(
            movie: Movie(
                id: -1,
                title: "Placeholder Title",
                overview: "",
                posterPath: nil,
                backdropPath: nil,
                releaseDate: "0000-00-00",
                voteAverage: 0
            )
        )
        .redacted(reason: .placeholder)
        .accessibilityHidden(true)
    }
}
