import Foundation

/// Configures automatic retry with exponential back-off for transient network failures.
struct RetryPolicy: Sendable {
    /// Maximum number of attempts including the first try.
    var maxAttempts: Int
    /// Base delay before the second attempt.
    var baseDelay: Duration
    /// Multiplier applied to the delay after each subsequent failure.
    var multiplier: Double
    /// Fraction of the current delay added as random jitter (0–1) to avoid thundering-herd.
    var jitterFraction: Double

    /// Default production policy: 3 attempts, 1 s base delay, doubling each time.
    static let `default` = RetryPolicy(
        maxAttempts: 3,
        baseDelay: .seconds(1),
        multiplier: 2.0,
        jitterFraction: 0.3
    )

    /// Single-attempt policy. useful for search (debounce already guards) or tests.
    static let none = RetryPolicy(
        maxAttempts: 1,
        baseDelay: .zero,
        multiplier: 1.0,
        jitterFraction: 0
    )

    /// Executes `operation`, retrying on transient errors with exponential back-off.
    ///
    /// - Cancellation is propagated immediately without retry.
    /// - A `NetworkError.rateLimited(retryAfter:)` waits for the server-specified delay
    ///   instead of the computed back-off.
    /// - Permanent errors (4xx except 429, decoding failures, invalid URLs) are thrown
    ///   immediately without retrying.
    func execute<T: Sendable>(_ operation: @Sendable () async throws -> T) async throws -> T {
        var delay = baseDelay
        var lastError: Error = NetworkError.transport(underlyingDescription: "unreachable")

        for attempt in 1 ... max(1, maxAttempts) {
            do {
                return try await operation()
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                lastError = error
                guard attempt < maxAttempts, isRetryable(error) else { throw error }

                if case NetworkError.rateLimited(let retryAfter) = error, let wait = retryAfter {
                    try await Task.sleep(for: .seconds(wait))
                } else {
                    let base = durationToSeconds(delay)
                    let jitter = base * jitterFraction * Double.random(in: -0.5 ... 0.5)
                    try await Task.sleep(for: .seconds(max(0, base + jitter)))
                    delay = .seconds(base * multiplier)
                }
            }
        }
        throw lastError
    }

    // MARK: - Private

    private func isRetryable(_ error: Error) -> Bool {
        switch error as? NetworkError {
        case .transport: return true
        case .rateLimited: return true
        case .invalidResponse(let code): return [500, 502, 503, 504].contains(code)
        default: return false
        }
    }

    private func durationToSeconds(_ d: Duration) -> Double {
        let (seconds, attoseconds) = d.components
        return Double(seconds) + Double(attoseconds) * 1e-18
    }
}
