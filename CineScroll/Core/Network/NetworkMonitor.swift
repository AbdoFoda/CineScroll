import Foundation
import Network

/// Observes device-level network reachability via `NWPathMonitor`.
///
/// Call `start()` once at launch (done inside `AppDependencies.live()`).
/// The `isConnected` and `isExpensive` properties update on `@MainActor`
/// and are safe to observe directly from SwiftUI views via `@Observable`.
@Observable
final class NetworkMonitor: @unchecked Sendable {
    /// `true` when at least one usable network path is available.
    private(set) var isConnected: Bool = true
    /// `true` when the active path uses a cellular or personal-hotspot link.
    private(set) var isExpensive: Bool = false

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "cinescroll.network-monitor", qos: .utility)

    init() {}

    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.isConnected = path.status == .satisfied
                self?.isExpensive = path.isExpensive
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
