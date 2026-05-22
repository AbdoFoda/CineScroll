import Foundation
import UIKit

/// Launch-time configuration when the app runs under XCUITest.
enum UITestConfiguration {
    static let launchArgument = "-ui-testing"

    static var isActive: Bool {
        ProcessInfo.processInfo.arguments.contains(launchArgument)
    }

    static func applyIfNeeded() {
        guard isActive else { return }
        Task {
            await MainActor.run {
                UIView.setAnimationsEnabled(false)
            }
        }
    }
}
