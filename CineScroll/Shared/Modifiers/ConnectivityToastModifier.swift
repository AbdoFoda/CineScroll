import SwiftUI

/// Overlays a `NetworkErrorToast` at the bottom of any view, driven entirely by a
/// `ConnectivityState` instance. Views never need to subscribe to notifications or
/// hold `isBackOnline` state themselves.
///
/// Usage:
/// ```swift
/// ContentView()
///     .connectivityToast(state: viewModel.connectivity, onRetry: { viewModel.retry() })
/// ```
struct ConnectivityToastModifier: ViewModifier {
    let state: ConnectivityState
    var onRetry: () -> Void
    var bottomPadding: CGFloat
    /// Set to `false` to suppress the toast entirely (e.g. detail screen with no initial movie).
    var isEnabled: Bool

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if isEnabled {
                    if state.isBackOnline {
                        NetworkErrorToast(state: .backOnline, onDismiss: { state.dismissBackOnline() })
                            .padding(.bottom, bottomPadding)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else if let error = state.connectivityError {
                        NetworkErrorToast(
                            state: .offline(error),
                            onRetry: onRetry,
                            onDismiss: { state.clearError() }
                        )
                        .padding(.bottom, bottomPadding)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .animation(.spring(duration: 0.3), value: state.isBackOnline)
            .animation(.spring(duration: 0.3), value: state.connectivityError != nil)
    }
}

extension View {
    /// Attaches the connectivity toast to this view.
    ///
    /// - Parameters:
    ///   - state: The `ConnectivityState` owned by the screen's ViewModel.
    ///   - onRetry: Action for the "Retry" button in the offline toast.
    ///   - bottomPadding: Extra space below the toast (default `CineSpacing.md`).
    ///   - isEnabled: Pass `false` to fully suppress the toast (e.g. deep-link detail with no cached movie).
    func connectivityToast(
        state: ConnectivityState,
        onRetry: @escaping () -> Void,
        bottomPadding: CGFloat = CineSpacing.md,
        isEnabled: Bool = true
    ) -> some View {
        modifier(ConnectivityToastModifier(
            state: state,
            onRetry: onRetry,
            bottomPadding: bottomPadding,
            isEnabled: isEnabled
        ))
    }
}
