import XCTest

final class DeepLinkUITests: CineScrollUITestCase {
    func testDeepLinkOpensMovieDetail() throws {
        waitForNowPlayingReady()

        let url = URL(string: "cineScroll://movie/\(UITestID.matrixMovieID)")!
        XCUIDevice.shared.system.open(url)

        waitFor(app.navigationBars["The Matrix"])
        XCTAssertTrue(app.staticTexts["The Matrix"].waitForExistence(timeout: 8))
    }
}
