import XCTest
@testable import CineScroll

final class NetworkErrorTests: XCTestCase {

    // MARK: - userFacingMessage

    func testUserFacingMessageInvalidURL() {
        XCTAssertEqual(NetworkError.invalidURL.userFacingMessage, "Could not build a valid request.")
    }

    func testUserFacingMessageInvalidResponse() {
        let msg = NetworkError.invalidResponse(statusCode: 503).userFacingMessage
        XCTAssertTrue(msg.contains("503"), "Expected status code 503 in message, got: \(msg)")
    }

    func testUserFacingMessageDecodingFailed() {
        let msg = NetworkError.decodingFailed(underlyingDescription: "bad key").userFacingMessage
        XCTAssertEqual(msg, "Could not read the server data.")
    }

    func testUserFacingMessageNoData() {
        XCTAssertEqual(NetworkError.noData.userFacingMessage, "No data returned from the server.")
    }

    func testUserFacingMessageTransport() {
        let msg = NetworkError.transport(underlyingDescription: "timeout").userFacingMessage
        XCTAssertTrue(msg.lowercased().contains("network"), "Expected 'network' in message, got: \(msg)")
    }

    func testUserFacingMessageMissingAPIKey() {
        let msg = NetworkError.missingAPIKey.userFacingMessage
        XCTAssertTrue(msg.contains("CINESCROLL_API_BASE_URL"), "Expected config key in message, got: \(msg)")
    }

    func testUserFacingMessageOffline() {
        let msg = NetworkError.offline.userFacingMessage
        XCTAssertTrue(msg.lowercased().contains("offline"), "Expected 'offline' in message, got: \(msg)")
    }

    func testUserFacingMessageRateLimited() {
        let msg = NetworkError.rateLimited(retryAfter: 60).userFacingMessage
        XCTAssertTrue(msg.lowercased().contains("wait"), "Expected 'wait' in message, got: \(msg)")
    }

    func testUserFacingMessageRateLimitedNoRetryAfter() {
        let msg = NetworkError.rateLimited(retryAfter: nil).userFacingMessage
        XCTAssertFalse(msg.isEmpty)
    }

    // MARK: - isConnectivityError
    func testIsConnectivityErrorTransport() {
        XCTAssertTrue(NetworkError.transport(underlyingDescription: "x").isConnectivityError)
    }

    func testIsConnectivityErrorOffline() {
        XCTAssertTrue(NetworkError.offline.isConnectivityError)
    }

    func testIsConnectivityErrorInvalidURL() {
        XCTAssertFalse(NetworkError.invalidURL.isConnectivityError)
    }

    func testIsConnectivityErrorInvalidResponse() {
        XCTAssertFalse(NetworkError.invalidResponse(statusCode: 404).isConnectivityError)
    }

    func testIsConnectivityErrorDecodingFailed() {
        XCTAssertFalse(NetworkError.decodingFailed(underlyingDescription: "x").isConnectivityError)
    }

    func testIsConnectivityErrorNoData() {
        XCTAssertFalse(NetworkError.noData.isConnectivityError)
    }

    func testIsConnectivityErrorMissingAPIKey() {
        XCTAssertFalse(NetworkError.missingAPIKey.isConnectivityError)
    }

    func testIsConnectivityErrorRateLimited() {
        XCTAssertFalse(NetworkError.rateLimited(retryAfter: nil).isConnectivityError)
    }

    // MARK: - Equatable
    func testEqualitySameCase() {
        XCTAssertEqual(NetworkError.offline, NetworkError.offline)
        XCTAssertEqual(NetworkError.invalidURL, NetworkError.invalidURL)
        XCTAssertEqual(NetworkError.noData, NetworkError.noData)
        XCTAssertEqual(
            NetworkError.invalidResponse(statusCode: 500),
            NetworkError.invalidResponse(statusCode: 500)
        )
        XCTAssertEqual(
            NetworkError.rateLimited(retryAfter: 30),
            NetworkError.rateLimited(retryAfter: 30)
        )
        XCTAssertEqual(
            NetworkError.rateLimited(retryAfter: nil),
            NetworkError.rateLimited(retryAfter: nil)
        )
    }

    func testEqualityDifferentCases() {
        XCTAssertNotEqual(NetworkError.offline, NetworkError.invalidURL)
        XCTAssertNotEqual(
            NetworkError.invalidResponse(statusCode: 500),
            NetworkError.invalidResponse(statusCode: 503)
        )
        XCTAssertNotEqual(
            NetworkError.rateLimited(retryAfter: 30),
            NetworkError.rateLimited(retryAfter: nil)
        )
    }
}
