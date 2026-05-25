import Foundation

// MARK: - ConnectivityState

/// Per-screen connectivity toast state. Each ViewModel owns one instance.
///
/// Assign `onReconnect` for a silent background refresh when coming back online,
/// and `onOffline` to react immediately when the device loses connectivity.
/// Wire live observation lazily via `configure(networkMonitor:)` from the View's `.task`.
@MainActor
@Observable
final class ConnectivityState {
    /// Non-nil while a connectivity error is surfaced as a bottom toast.
    private(set) var connectivityError: NetworkError?
    /// True for ~2 seconds after the device comes back online, driving the green "back online" toast.
    private(set) var isBackOnline: Bool = false

    var onReconnect: () -> Void = {}
    var onOffline: () -> Void = {}

    init() {}

    /// Starts observing `networkMonitor`. Second call is a no-op.
    func configure(networkMonitor: NetworkMonitor) {
        guard !isObserving else { return }
        isObserving = true
        startObserving(networkMonitor)
    }

    @ObservationIgnored private var isObserving = false

    // MARK: - Called by ViewModels

    /// Surfaces a connectivity error as a non-blocking bottom toast.
    func markError(_ error: NetworkError) {
        connectivityError = error
        isBackOnline = false
    }

    /// Silently clears the connectivity error without showing the "back online" banner.
    /// Use for explicit user dismissal (tapping ✕ on the offline toast).
    func clearError() {
        connectivityError = nil
    }

    /// Called when a network request succeeds.
    /// If a connectivity error was showing, clears it and triggers the "back online" banner
    /// so the user gets positive confirmation that the connection is restored.
    /// If no error was showing, this is a no-op for the toast.
    func reportSuccess() {
        if connectivityError != nil {
            isBackOnline = true
        }
        connectivityError = nil
    }

    /// Dismisses the "back online" banner (called by the toast's auto-dismiss timer).
    func dismissBackOnline() {
        isBackOnline = false
    }

    /// Handles a transition to online. Internal so unit tests can drive it without a live monitor.
    func handleReconnect() {
        if connectivityError != nil {
            connectivityError = nil
            isBackOnline = true
        }
        onReconnect()
    }

    /// Handles a transition to offline. Internal so unit tests can drive it without a live monitor.
    func handleNetworkOffline() {
        isBackOnline = false
        onOffline()
    }

    // MARK: - Private

    /// Observes `NetworkMonitor.isConnected` via `withObservationTracking` in a loop.
    /// The loop exits naturally when this `ConnectivityState` is deallocated (`guard let self`).
    private func startObserving(_ monitor: NetworkMonitor) {
        Task { @MainActor [weak self] in
            var lastConnected = monitor.isConnected
            while true {
                // Suspend until isConnected changes (fires once per tracking registration).
                await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                    withObservationTracking {
                        _ = monitor.isConnected
                    } onChange: {
                        continuation.resume()
                    }
                }
                guard let self else { break }
                let now = monitor.isConnected
                guard now != lastConnected else { continue }
                lastConnected = now
                if now {
                    handleReconnect()
                } else {
                    handleNetworkOffline()
                }
            }
        }
    }
}
