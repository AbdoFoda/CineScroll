import SwiftUI

/// Horizontal scrolling carousel of cast member avatars with names.
struct CastCarouselView: View {
    let cast: [CastMember]

    var body: some View {
        VStack(alignment: .leading, spacing: CineSpacing.sm) {
            Text("Cast")
                .font(.title3.bold())
                .padding(.horizontal, CineSpacing.lg)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: CineSpacing.lg) {
                    ForEach(cast) { member in
                        CastAvatarCell(member: member)
                    }
                }
                .padding(.horizontal, CineSpacing.lg)
                .padding(.vertical, CineSpacing.xs)
            }
        }
    }
}

// MARK: - Avatar cell

private struct CastAvatarCell: View {
    let member: CastMember

    var body: some View {
        VStack(spacing: CineSpacing.xs) {
            AsyncImageView(url: member.profileURL(), contentMode: .fill)
                .frame(width: CineSize.castAvatarSize, height: CineSize.castAvatarSize)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.secondary.opacity(0.15), lineWidth: 0.5))

            Text(member.name)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: CineSize.castAvatarSize)
        }
    }
}

// MARK: - Preview

#Preview("Cast Carousel") {
    CastCarouselView(cast: [
        CastMember(id: 6384,  name: "Keanu Reeves",       profilePath: "/4D0PpNI0kmP58hgrwGC3wCjxhnm.jpg"),
        CastMember(id: 2975,  name: "Laurence Fishburne", profilePath: "/mh0lZ1XsT84FayMNiT6Erh91mVu.jpg"),
        CastMember(id: 70851, name: "Carrie-Anne Moss",   profilePath: "/8iATAc5z5XOeZMjkFKIQQBHKoq1.jpg"),
        CastMember(id: 1331,  name: "Hugo Weaving",       profilePath: "/dQxPteXAjOT1Zjik1dHEP80cFU4.jpg"),
        CastMember(id: 1,     name: "No Photo Actor",     profilePath: nil),
    ])
    .preferredColorScheme(.dark)
    .background(Color.black)
}
