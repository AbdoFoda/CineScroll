import SwiftUI

extension View {
    /// Applies a stable accessibility identifier for UI tests (does not hide children).
    func cineAccessibility(_ identifier: String) -> some View {
        accessibilityIdentifier(identifier)
    }

    /// Identifies a scroll region without grouping children (keeps cards/buttons visible to XCUITest).
    func cineAccessibilityRegion(_ identifier: String) -> some View {
        accessibilityIdentifier(identifier)
    }
}
