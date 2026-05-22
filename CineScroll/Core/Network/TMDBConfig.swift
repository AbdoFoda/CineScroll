import Foundation

// MARK: - TMDBImageSize

/// TMDB CDN image size profiles. Choose the smallest size that meets the display resolution
/// to reduce bandwidth and in-process memory usage.
enum TMDBImageSize: String, Sendable {
    /// ~185 px wide: autocomplete rows, cast avatars.
    case w185
    /// ~342 px wide: grid cards on most phones.
    case w342
    /// ~500 px wide: fallback / mid-size contexts.
    case w500
    /// ~780 px wide: detail hero images on large phones and iPad.
    case w780

    var baseURLString: String { "https://image.tmdb.org/t/p/\(rawValue)" }
}

// MARK: - TMDBConfig

/// Central configuration for TMDB media URLs, the CineScroll API proxy base URL,
/// and shared URL cache capacities.
enum TMDBConfig {
    // MARK: URL Cache

    /// In-memory capacity for `URLCache.shared` (64 MB).
    static let urlCacheMemoryCapacity = 64 * 1024 * 1024
    /// On-disk capacity for `URLCache.shared` (256 MB).
    static let urlCacheDiskCapacity = 256 * 1024 * 1024

    private static func resolvedAPIBaseURLString() -> String {
        let raw = (Bundle.main.object(forInfoDictionaryKey: "CINESCROLL_API_BASE_URL") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !raw.isEmpty, !raw.contains("$(") else { return "" }
        return raw
    }

    /// CineScroll Cloudflare Worker base URL (no trailing slash), injected at build time.
    static let apiBaseURL: URL = {
        let raw = resolvedAPIBaseURLString()
        guard !raw.isEmpty, let url = URL(string: raw) else {
            return URL(string: "https://api.invalid.cinescroll")!
        }
        return url
    }()

    /// True when a valid proxy base URL is present in the built app.
    static var isConfigured: Bool {
        let raw = resolvedAPIBaseURLString()
        guard !raw.isEmpty else { return false }
        guard let url = URL(string: raw), let host = url.host, !host.isEmpty else { return false }
        return url.scheme == "https" || url.scheme == "http"
    }

    /// Builds an absolute TMDB CDN URL for `path` at the requested `size`.
    /// Returns `nil` when `path` is nil or empty.
    static func imageURL(path: String?, size: TMDBImageSize) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        let tail = path.hasPrefix("/") ? String(path.dropFirst()) : path
        return URL(string: "\(size.baseURLString)/\(tail)")
    }
}
