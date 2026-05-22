import SwiftUI

/// Standard inline error UI with an optional retry action.
struct ErrorView: View {
    let message: String
    var retryTitle: String = "Try again"
    var onRetry: (() -> Void)?

    var body: some View {
        ContentUnavailableView {
            Label("Something went wrong", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            if let onRetry {
                Button(retryTitle) {
                    onRetry()
                }
                .buttonStyle(.borderedProminent)
                .cineAccessibility(AccessibilityID.errorRetry)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
