import SafariServices
import SwiftUI

/// 16:9 YouTube thumbnail card with a play button.
/// Tapping opens the trailer in an in-app `SFSafariViewController` sheet,
/// keeping the user inside the app while still showing the full YouTube player.
struct TrailerCardView: View {
    let trailer: TrailerInfo
    @State private var showSafari = false

    var body: some View {
        Button { showSafari = true } label: {
            ZStack {
                AsyncImageView(url: trailer.thumbnailURL, contentMode: .fill)
                    .overlay(Color.black.opacity(0.3))

                playButton
            }
            .aspectRatio(16 / 9, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: CineRadius.md))
            .overlay(alignment: .bottomLeading) { watchLabel }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showSafari) {
            if let url = trailer.watchURL {
                SafariView(url: url)
                    .ignoresSafeArea()
            }
        }
    }

    // MARK: - Sub-views

    private var playButton: some View {
        Circle()
            .fill(.red)
            .frame(width: 56, height: 56)
            .overlay(
                Image(systemName: "play.fill")
                    .foregroundStyle(.white)
                    .font(.title3)
                    .offset(x: 2)
            )
            .shadow(color: .black.opacity(0.4), radius: 10, y: 4)
    }

    private var watchLabel: some View {
        Label("Watch Trailer", systemImage: "play.rectangle.fill")
            .font(.caption.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, CineSpacing.sm)
            .padding(.vertical, CineSpacing.xs)
            .background(.black.opacity(0.6))
            .clipShape(Capsule())
            .padding(CineSpacing.sm)
    }
}

// MARK: - SafariView

/// Thin `UIViewControllerRepresentable` wrapper around `SFSafariViewController`.
private struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        return SFSafariViewController(url: url, configuration: config)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// MARK: - Preview

#Preview("Trailer Card") {
    TrailerCardView(
        trailer: TrailerInfo(youtubeKey: "k-YAcjaLuSI")
    )
    .padding()
    .preferredColorScheme(.dark)
    .background(Color.black)
}
