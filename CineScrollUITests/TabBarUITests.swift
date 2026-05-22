import XCTest

final class TabBarUITests: CineScrollUITestCase {
    func testTabBarSwitchesBetweenNowPlayingAndSearch() throws {
        waitForNowPlayingReady()
        XCTAssertTrue(nowPlayingTab.isSelected)

        openSearchTab()
        XCTAssertTrue(app.staticTexts["Search movies"].waitForExistence(timeout: 4))
        XCTAssertTrue(searchTab.isSelected)

        openNowPlayingTab()
        XCTAssertTrue(nowPlayingTab.isSelected)
    }
}
