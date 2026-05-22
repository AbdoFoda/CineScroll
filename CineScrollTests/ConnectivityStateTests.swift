import XCTest
@testable import CineScroll

/// Tests `ConnectivityState`. state mutation and callback wiring.
@MainActor
final class ConnectivityStateTests: XCTestCase {

    // MARK: - markError

    func testMarkErrorSetsConnectivityError() {
        let state = ConnectivityState()
        state.markError(.offline)
        XCTAssertEqual(state.connectivityError, .offline)
    }

    func testMarkErrorClearsBackOnlineBanner() {
        let state = ConnectivityState()
        state.markError(.offline)
        XCTAssertFalse(state.isBackOnline)
    }

    func testMarkErrorOverwritesPreviousError() {
        let state = ConnectivityState()
        state.markError(.offline)
        state.markError(.transport(underlyingDescription: "new"))
        XCTAssertEqual(state.connectivityError, .transport(underlyingDescription: "new"))
    }

    // MARK: - clearError

    func testClearErrorRemovesConnectivityError() {
        let state = ConnectivityState()
        state.markError(.offline)
        state.clearError()
        XCTAssertNil(state.connectivityError)
    }

    func testClearErrorWhenNilIsNoOp() {
        let state = ConnectivityState()
        XCTAssertNil(state.connectivityError)
        state.clearError()
        XCTAssertNil(state.connectivityError)
    }

    func testClearErrorDoesNotShowBackOnlineBanner() {
        let state = ConnectivityState()
        state.markError(.offline)
        state.clearError()
        XCTAssertFalse(state.isBackOnline, "clearError (dismiss) must not trigger 'back online' banner")
    }

    // MARK: - reportSuccess

    func testReportSuccessClearsError() {
        let state = ConnectivityState()
        state.markError(.offline)
        state.reportSuccess()
        XCTAssertNil(state.connectivityError)
    }

    func testReportSuccessShowsBannerWhenErrorWasSet() {
        let state = ConnectivityState()
        state.markError(.offline)
        state.reportSuccess()
        XCTAssertTrue(state.isBackOnline, "reportSuccess after an error must show 'back online' banner")
    }

    func testReportSuccessWithNoErrorDoesNotShowBanner() {
        let state = ConnectivityState()
        state.reportSuccess()
        XCTAssertFalse(state.isBackOnline, "reportSuccess with no prior error must not show banner")
    }

    func testReportSuccessTransportErrorShowsBanner() {
        let state = ConnectivityState()
        state.markError(.transport(underlyingDescription: "timeout"))
        state.reportSuccess()
        XCTAssertTrue(state.isBackOnline)
        XCTAssertNil(state.connectivityError)
    }

    // MARK: - dismissBackOnline

    func testDismissBackOnlineClearsBannerFlag() {
        let state = ConnectivityState()
        state.markError(.offline)
        state.reportSuccess()
        XCTAssertTrue(state.isBackOnline)
        state.dismissBackOnline()
        XCTAssertFalse(state.isBackOnline)
    }

    func testDismissBackOnlineWhenFalseIsNoOp() {
        let state = ConnectivityState()
        state.dismissBackOnline()
        XCTAssertFalse(state.isBackOnline)
    }

    // MARK: - onReconnect / onOffline callback wiring
    func testOnReconnectCallbackFiredWithPriorError() {
        let state = ConnectivityState()
        var reconnectCalled = false
        state.onReconnect = { reconnectCalled = true }

        state.markError(.offline)
        state.handleReconnect()

        XCTAssertTrue(reconnectCalled, "onReconnect must fire when handleReconnect is called")
    }

    func testOnReconnectCallbackFiredWithoutPriorError() {
        let state = ConnectivityState()
        var reconnectCalled = false
        state.onReconnect = { reconnectCalled = true }

        // No prior error. onReconnect is still called (VM decides what to do).
        state.handleReconnect()

        XCTAssertTrue(reconnectCalled, "onReconnect is always called on reconnect (VM decides action)")
    }

    func testOnOfflineCallbackIsFired() {
        let state = ConnectivityState()
        var offlineCalled = false
        state.onOffline = { offlineCalled = true }

        state.handleNetworkOffline()

        XCTAssertTrue(offlineCalled, "onOffline closure must be invoked when handleNetworkOffline fires")
    }

    func testReconnectShowsBannerWhenErrorIsSet() {
        let state = ConnectivityState()
        state.markError(.offline)

        state.handleReconnect()

        XCTAssertTrue(state.isBackOnline, "handleReconnect with a prior error must show 'back online' banner")
        XCTAssertNil(state.connectivityError)
    }

    func testOfflineClearsBackOnlineBanner() {
        let state = ConnectivityState()
        state.markError(.offline)
        state.reportSuccess()
        XCTAssertTrue(state.isBackOnline)

        state.handleNetworkOffline()

        XCTAssertFalse(state.isBackOnline, "Going offline must clear the 'back online' banner")
    }
}
