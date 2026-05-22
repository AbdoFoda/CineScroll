import SwiftUI
import UIKit

// MARK: - ImageCache

/// Process-wide LRU cache for decoded UIImages, keyed by absolute URL string.
/// Clears itself on memory warnings.
final class ImageCache: @unchecked Sendable {
    static let shared = ImageCache()

    private let cache = NSCache<NSString, UIImage>()

    private init() {
        cache.countLimit = 200
        cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB decoded pixels

        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            self?.cache.removeAllObjects()
        }
    }

    func image(for key: String) -> UIImage? {
        cache.object(forKey: key as NSString)
    }

    func insert(_ image: UIImage, for key: String) {
        // Cost = approximate byte size of the decoded bitmap.
        let cost = Int(image.size.width * image.size.height * image.scale * image.scale * 4)
        cache.setObject(image, forKey: key as NSString, cost: cost)
    }

    func removeAll() {
        cache.removeAllObjects()
    }
}

// MARK: - AsyncImageView

/// Loads remote images asynchronously, with three-tier fallback:
/// 1. In-process `ImageCache` (decoded UIImage. fastest)
/// 2. Network via `imageHTTPClient` environment key (respects URLCache HTTP caching)
/// 3. `URLCache.shared` stale entry when offline
///
/// Uses the `imageHTTPClient` environment key so tests can substitute a mock client.
struct AsyncImageView: View {
    let url: URL?
    var contentMode: ContentMode = .fill

    @Environment(\.useSnapshotPlaceholders) private var useSnapshotPlaceholders
    @Environment(\.imageHTTPClient) private var httpClient
    @State private var loadedImage: UIImage?

    var body: some View {
        ZStack {
            if useSnapshotPlaceholders {
                snapshotPlaceholder
            } else {
                Color.secondary.opacity(CineOpacity.placeholderFill)
                if let loadedImage {
                    Image(uiImage: loadedImage)
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                }
            }
        }
        .clipped()
        .task(id: url?.absoluteString) {
            guard !useSnapshotPlaceholders else { return }
            await load()
        }
    }

    // MARK: - Private

    private var snapshotPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.22, green: 0.24, blue: 0.30),
                    Color(red: 0.14, green: 0.15, blue: 0.20),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "film")
                .font(.title2)
                .foregroundStyle(.white.opacity(0.35))
        }
    }

    private func load() async {
        loadedImage = nil
        guard let url else { return }
        let key = url.absoluteString

        if let cached = ImageCache.shared.image(for: key) {
            loadedImage = cached
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        do {
            let (data, _) = try await httpClient.data(for: request)
            if Task.isCancelled { return }
            if let image = UIImage(data: data) {
                ImageCache.shared.insert(image, for: key)
                loadedImage = image
            }
        } catch {
            if Task.isCancelled { return }
            // 3. Offline fallback. serve stale URLCache entry if available.
            var cached = URLRequest(url: url, cachePolicy: .returnCacheDataDontLoad)
            cached.httpMethod = "GET"
            if let (data, _) = try? await URLSession.shared.data(for: cached),
               !Task.isCancelled,
               let image = UIImage(data: data) {
                ImageCache.shared.insert(image, for: key)
                loadedImage = image
            }
        }
    }
}
