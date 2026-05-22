import XCTest
import Synchronization
@testable import CineScroll

final class RetryPolicyTests: XCTestCase {

    // MARK: - Helpers

    private let fastPolicy = RetryPolicy(
        maxAttempts: 3,
        baseDelay: .milliseconds(1),
        multiplier: 2.0,
        jitterFraction: 0
    )

    // MARK: - Attempt counting
    func testExhaustsMaxAttempts() async throws {
        let counter = Mutex<Int>(0)
        do {
            _ = try await fastPolicy.execute {
                counter.withLock { $0 += 1 }
                throw NetworkError.transport(underlyingDescription: "transient")
            }
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(counter.withLock { $0 }, 3, "Should attempt exactly maxAttempts times")
        }
    }

    func testSingleAttemptPolicyNeverRetries() async throws {
        let counter = Mutex<Int>(0)
        do {
            _ = try await RetryPolicy.none.execute {
                counter.withLock { $0 += 1 }
                throw NetworkError.transport(underlyingDescription: "transient")
            }
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(counter.withLock { $0 }, 1, "Policy.none must attempt exactly once")
        }
    }

    func testSuccessOnFirstAttemptNeverRetries() async throws {
        let counter = Mutex<Int>(0)
        let result = try await fastPolicy.execute {
            counter.withLock { $0 += 1 }
            return "ok"
        }
        XCTAssertEqual(result, "ok")
        XCTAssertEqual(counter.withLock { $0 }, 1)
    }

    func testSuccessOnSecondAttempt() async throws {
        let counter = Mutex<Int>(0)
        let result = try await fastPolicy.execute {
            let n = counter.withLock { c -> Int in
                c += 1
                return c
            }
            if n < 2 { throw NetworkError.transport(underlyingDescription: "x") }
            return "recovered"
        }
        XCTAssertEqual(result, "recovered")
        XCTAssertEqual(counter.withLock { $0 }, 2)
    }

    // MARK: - Non-retryable errors
    func testOfflineErrorNotRetried() async throws {
        let counter = Mutex<Int>(0)
        do {
            _ = try await fastPolicy.execute { () async throws -> String in
                counter.withLock { $0 += 1 }
                throw NetworkError.offline
            }
            XCTFail("Expected offline error")
        } catch let error as NetworkError {
            XCTAssertEqual(error, .offline)
            XCTAssertEqual(counter.withLock { $0 }, 1, "Offline must not be retried")
        }
    }

    func testDecodingFailureNotRetried() async throws {
        let counter = Mutex<Int>(0)
        do {
            _ = try await fastPolicy.execute { () async throws -> String in
                counter.withLock { $0 += 1 }
                throw NetworkError.decodingFailed(underlyingDescription: "bad json")
            }
            XCTFail("Expected decoding error")
        } catch {
            XCTAssertEqual(counter.withLock { $0 }, 1, "Decoding failures must not be retried")
        }
    }

    func testClientError404NotRetried() async throws {
        let counter = Mutex<Int>(0)
        do {
            _ = try await fastPolicy.execute { () async throws -> String in
                counter.withLock { $0 += 1 }
                throw NetworkError.invalidResponse(statusCode: 404)
            }
            XCTFail("Expected 404 error")
        } catch {
            XCTAssertEqual(counter.withLock { $0 }, 1, "404 must not be retried")
        }
    }

    func testClientError401NotRetried() async throws {
        let counter = Mutex<Int>(0)
        do {
            _ = try await fastPolicy.execute { () async throws -> String in
                counter.withLock { $0 += 1 }
                throw NetworkError.missingAPIKey
            }
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(counter.withLock { $0 }, 1, "Missing API key must not be retried")
        }
    }

    // MARK: - Retryable server errors
    func testServerError500IsRetried() async throws {
        let counter = Mutex<Int>(0)
        do {
            _ = try await fastPolicy.execute { () async throws -> String in
                counter.withLock { $0 += 1 }
                throw NetworkError.invalidResponse(statusCode: 500)
            }
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(counter.withLock { $0 }, 3, "500 should be retried to exhaustion")
        }
    }

    func testServerError503IsRetried() async throws {
        let counter = Mutex<Int>(0)
        do {
            _ = try await fastPolicy.execute { () async throws -> String in
                counter.withLock { $0 += 1 }
                throw NetworkError.invalidResponse(statusCode: 503)
            }
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(counter.withLock { $0 }, 3)
        }
    }

    func testRateLimitedIsRetried() async throws {
        let counter = Mutex<Int>(0)
        // Use nil retryAfter so we get default backoff (not a real 60-second wait)
        let policy = RetryPolicy(maxAttempts: 2, baseDelay: .milliseconds(1), multiplier: 1, jitterFraction: 0)
        do {
            _ = try await policy.execute { () async throws -> String in
                counter.withLock { $0 += 1 }
                throw NetworkError.rateLimited(retryAfter: nil)
            }
            XCTFail("Expected rate-limited error")
        } catch {
            XCTAssertEqual(counter.withLock { $0 }, 2, "rateLimited should trigger a retry")
        }
    }

    // MARK: - Cancellation
    func testCancellationPropagatedImmediately() async throws {
        let counter = Mutex<Int>(0)
        do {
            _ = try await fastPolicy.execute {
                counter.withLock { $0 += 1 }
                throw CancellationError()
            }
            XCTFail("Expected CancellationError")
        } catch is CancellationError {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        XCTAssertEqual(counter.withLock { $0 }, 1, "Cancellation must not be retried")
    }

    func testExternalCancellationStopsRetries() async throws {
        let counter = Mutex<Int>(0)
        // Long backoff so we have time to cancel
        let longPolicy = RetryPolicy(
            maxAttempts: 10,
            baseDelay: .seconds(10),
            multiplier: 1,
            jitterFraction: 0
        )
        let task = Task {
            do {
                _ = try await longPolicy.execute { () async throws -> String in
                    counter.withLock { $0 += 1 }
                    throw NetworkError.transport(underlyingDescription: "x")
                }
            } catch {
                // Either CancellationError from the task or NetworkError after 1 attempt
            }
        }
        // Cancel after first attempt has a chance to run
        try await Task.sleep(for: .milliseconds(10))
        task.cancel()
        await task.value

        // Should have attempted only 1 time before cancellation during sleep
        XCTAssertLessThanOrEqual(counter.withLock { $0 }, 2)
    }
}
