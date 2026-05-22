import SwiftUI
@testable import CineScroll

/// Snapshot tests for `NetworkErrorToast` and `ConnectivityToastModifier`.
///
/// Each state is captured in light + dark to catch colour-scheme regressions.
@MainActor
final class ConnectivitySnapshotsTests: SnapshotTestCase {

    // MARK: - NetworkErrorToast states

    func testToastOfflineNoWifi() {
        assertCineColorSchemeSnapshots(
            of: toastContainer(NetworkErrorToast(state: .offline(.offline), onRetry: {}, onDismiss: {})),
            size: SnapshotSize.toastPanel
        )
    }

    func testToastOfflineServerError() {
        assertCineColorSchemeSnapshots(
            of: toastContainer(NetworkErrorToast(state: .offline(.invalidResponse(statusCode: 503)), onRetry: {})),
            size: SnapshotSize.toastPanel
        )
    }

    func testToastOfflineRateLimited() {
        assertCineColorSchemeSnapshots(
            of: toastContainer(NetworkErrorToast(state: .offline(.rateLimited(retryAfter: 30)))),
            size: SnapshotSize.toastPanel
        )
    }

    func testToastOfflineTransportError() {
        assertCineColorSchemeSnapshots(
            of: toastContainer(NetworkErrorToast(
                state: .offline(.transport(underlyingDescription: "Timeout")),
                onRetry: {},
                onDismiss: {}
            )),
            size: SnapshotSize.toastPanel
        )
    }

    func testToastBackOnline() {
        assertCineColorSchemeSnapshots(
            of: toastContainer(NetworkErrorToast(state: .backOnline, onDismiss: {})),
            size: SnapshotSize.toastPanel
        )
    }

    /// No retry or dismiss buttons. toast still renders message + icon only.
    func testToastOfflineWithNoButtons() {
        assertCineColorSchemeSnapshots(
            of: toastContainer(NetworkErrorToast(state: .offline(.offline))),
            size: SnapshotSize.toastPanel
        )
    }

    // MARK: - ConnectivityToastModifier integration

    func testModifierShowsOfflineToast() {
        let state = ConnectivityState()
        state.markError(.offline)

        assertCineColorSchemeSnapshots(
            of: modifierHost(connectivityState: state),
            size: SnapshotSize.phone
        )
    }

    func testModifierShowsBackOnlineBanner() {
        let state = ConnectivityState()
        state.markError(.offline)
        state.reportSuccess()

        assertCineColorSchemeSnapshots(
            of: modifierHost(connectivityState: state),
            size: SnapshotSize.phone
        )
    }

    func testModifierShowsNothingWhenNoError() {
        let state = ConnectivityState()

        assertCineColorSchemeSnapshots(
            of: modifierHost(connectivityState: state),
            size: SnapshotSize.phone
        )
    }

    func testModifierDisabledHidesEvenWithError() {
        let state = ConnectivityState()
        state.markError(.offline)

        assertCineColorSchemeSnapshots(
            of: modifierHost(connectivityState: state, isEnabled: false),
            size: SnapshotSize.phone
        )
    }

    // MARK: - Helpers

    private func toastContainer<V: View>(_ toast: V) -> some View {
        ZStack(alignment: .bottom) {
            Color.gray.opacity(0.08).ignoresSafeArea()
            toast.padding(.bottom, CineSpacing.lg)
        }
    }

    private func modifierHost(connectivityState: ConnectivityState, isEnabled: Bool = true) -> some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack {
                Spacer()
                Text("Content Area")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .connectivityToast(
            state: connectivityState,
            onRetry: {},
            bottomPadding: CineSpacing.md,
            isEnabled: isEnabled
        )
    }
}

// MARK: - SnapshotSize extension

private extension SnapshotSize {
    static let toastPanel = CGSize(width: 393, height: 100)
}
