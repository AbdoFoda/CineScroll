import Foundation
@testable import CineScroll

/// Test double for `HTTPClient` that routes requests to canned responses.
final class MockHTTPClient: HTTPClient, @unchecked Sendable {
    private let handler: @Sendable (URLRequest) async throws -> (Data, URLResponse)

    init(handler: @escaping @Sendable (URLRequest) async throws -> (Data, URLResponse)) {
        self.handler = handler
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await handler(request)
    }
}
