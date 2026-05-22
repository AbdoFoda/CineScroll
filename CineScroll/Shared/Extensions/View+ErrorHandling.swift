import SwiftUI

extension View {
    /// Covers the view with a retryable error surface when `isPresented` is true.
    func errorOverlay(isPresented: Bool, message: String, onRetry: @escaping () -> Void) -> some View {
        ZStack {
            self
            if isPresented {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                ErrorView(message: message, onRetry: onRetry)
                    .padding()
            }
        }
    }
}
