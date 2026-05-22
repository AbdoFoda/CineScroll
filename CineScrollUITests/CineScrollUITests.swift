import XCTest

final class CineScrollUITests: CineScrollUITestCase {
    func testAppLaunchesIntoNowPlaying() throws {
        waitForNowPlayingReady()
    }

    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let launchApp = XCUIApplication()
            launchApp.launchArguments = [UITestID.launchArgument]
            launchApp.launch()
        }
    }
}
