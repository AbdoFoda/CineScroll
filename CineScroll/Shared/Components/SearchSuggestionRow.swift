import SwiftUI

/// Compact row shown in the search field autocomplete suggestion list.
struct SearchSuggestionRow: View {
    let movie: Movie

    var body: some View {
        HStack(spacing: CineSpacing.md) {
            AsyncImageView(url: movie.posterURL(size: .w185))
                .frame(
                    width: CineSize.suggestionPosterWidth,
                    height: CineSize.suggestionPosterHeight
                )
                .clipShape(RoundedRectangle(cornerRadius: CineRadius.sm, style: .continuous))

            VStack(alignment: .leading, spacing: CineSpacing.xxs) {
                Text(movie.title)
                    .font(.body)
                    .lineLimit(1)
                if let release = movie.formattedReleaseDate {
                    Text(release)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)

            Text(String(format: "★ %.1f", movie.voteAverage))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, CineSpacing.xs)
        .cineAccessibility(AccessibilityID.suggestionRow(movie.id))
    }
}
