import XCTest

final class NowPlayingUITests: CineScrollUITestCase {
    func testNowPlayingShowsMovieGrid() throws {
        let app = XCUIApplication()
        app.activate()
        waitForNowPlayingReady()
    }

    func testNavigateToMovieDetailFromGrid() throws {
        waitForNowPlayingReady()
        waitForMovieCard(UITestID.matrixMovieID).tap()

        waitFor(app.navigationBars["The Matrix"])
        XCTAssertTrue(app.staticTexts["The Matrix"].waitForExistence(timeout: 4))
    }

    func testDetailBackReturnsToGrid() throws {
        waitForNowPlayingReady()
        waitForMovieCard(UITestID.matrixMovieID).tap()
        waitFor(app.navigationBars["The Matrix"])

        app.navigationBars.buttons.element(boundBy: 0).tap()
        waitForNowPlayingReady()
    }
}
