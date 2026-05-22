import XCTest

final class CineScrollUITestsLaunchTests: XCTestCase {
    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        false
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunchScreenshot() throws {
        let app = XCUIApplication()
        app.launchArguments = [UITestID.launchArgument]
        app.launch()

        waitForGrid(in: app)

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Now Playing"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    private func waitForGrid(in app: XCUIApplication) {
        let grid = app.otherElements[UITestID.nowPlayingGrid]
        _ = grid.waitForExistence(timeout: 12)
    }
}
