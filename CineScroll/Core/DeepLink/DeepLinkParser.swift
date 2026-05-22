import Foundation

/// Parses `cineScroll://movie/{id}` deep links into numeric ids.
enum DeepLinkParser {
    /// Extracts a movie id from supported deep link URLs.
    static func movieID(from url: URL) -> Int? {
        guard let scheme = url.scheme?.lowercased(), scheme == "cinescroll" else {
            return nil
        }
        guard url.host?.lowercased() == "movie" else {
            return nil
        }
        let trimmed = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !trimmed.isEmpty else { return nil }
        return Int(trimmed)
    }
}
