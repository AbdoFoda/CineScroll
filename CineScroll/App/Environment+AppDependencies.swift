import SwiftUI

private enum AppDependenciesKey: EnvironmentKey {
    static let defaultValue: AppDependencies = .preview()
}

private enum ImageHTTPClientKey: EnvironmentKey {
    // Default to a shared URLSession-backed client
    static let defaultValue: any HTTPClient = URLSessionHTTPClient()
}

extension EnvironmentValues {
    /// Global app dependencies (repository, stores) injected at the root.
    var appDependencies: AppDependencies {
        get { self[AppDependenciesKey.self] }
        set { self[AppDependenciesKey.self] = newValue }
    }

    /// HTTP client used by `AsyncImageView` for image loading.
    /// Defaults to `URLSessionHTTPClient` so no explicit wiring is needed in production;
    /// substitute a mock in snapshot tests or unit tests that exercise image loading.
    var imageHTTPClient: any HTTPClient {
        get { self[ImageHTTPClientKey.self] }
        set { self[ImageHTTPClientKey.self] = newValue }
    }
}
