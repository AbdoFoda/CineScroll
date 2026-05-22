import SwiftUI

/// When true, remote images render deterministic placeholders (snapshot / preview stability).
enum SnapshotConfiguration {
    static var usePlaceholders: Bool {
        ProcessInfo.processInfo.environment["SNAPSHOT_TESTING"] == "1"
    }
}

private struct UseSnapshotPlaceholdersKey: EnvironmentKey {
    static let defaultValue: Bool = SnapshotConfiguration.usePlaceholders
}

extension EnvironmentValues {
    var useSnapshotPlaceholders: Bool {
        get { self[UseSnapshotPlaceholdersKey.self] }
        set { self[UseSnapshotPlaceholdersKey.self] = newValue }
    }
}
