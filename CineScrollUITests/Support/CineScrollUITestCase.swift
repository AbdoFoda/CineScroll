import XCTest

@MainActor
class CineScrollUITestCase: XCTestCase {
    private(set) var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        await MainActor.run {
            app = XCUIApplication()
            app.launchArguments = [UITestID.launchArgument]
            app.launch()
        }
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20))
    }

    func waitFor(
        _ element: XCUIElement,
        timeout: TimeInterval = 20,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            element.waitForExistence(timeout: timeout),
            "Expected \(element) to exist",
            file: file,
            line: line
        )
    }

    var nowPlayingTab: XCUIElement {
        app.tabBars.buttons["Now Playing"]
    }

    var searchTab: XCUIElement {
        app.tabBars.buttons["Search"]
    }

    func waitForNowPlayingReady(file: StaticString = #filePath, line: UInt = #line) {
        waitFor(app.navigationBars["Now Playing"], file: file, line: line)
        XCTAssertTrue(
            app.staticTexts["The Matrix"].waitForExistence(timeout: 15),
            "Expected preview catalog movie to load",
            file: file,
            line: line
        )
    }

    func openSearchTab(file: StaticString = #filePath, line: UInt = #line) {
        searchTab.tap()
        waitFor(app.navigationBars["Search"], file: file, line: line)
    }

    func openNowPlayingTab(file: StaticString = #filePath, line: UInt = #line) {
        nowPlayingTab.tap()
        waitForNowPlayingReady(file: file, line: line)
    }

    /// Finds a movie card by accessibility id (any element type). Prefer after `waitForMovieCard`.
    func movieCard(_ id: Int) -> XCUIElement {
        if let match = findMovieCard(id) {
            return match
        }
        let title = UITestID.previewTitle(for: id)
        if !title.isEmpty, app.buttons[title].exists {
            return app.buttons[title]
        }
        return app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == %@", UITestID.movieCard(id)))
            .firstMatch
    }

    @discardableResult
    func waitForMovieCard(
        _ id: Int,
        timeout: TimeInterval = 15,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if let match = findMovieCard(id), match.exists {
                return match
            }
            let title = UITestID.previewTitle(for: id)
            if !title.isEmpty {
                let byTitle = app.buttons[title]
                if byTitle.waitForExistence(timeout: 0.2) {
                    return byTitle
                }
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
        XCTFail(
            "Expected movie card \(UITestID.movieCard(id)) to exist",
            file: file,
            line: line
        )
        return app.buttons[UITestID.movieCard(id)]
    }

    private func findMovieCard(_ id: Int) -> XCUIElement? {
        let identifier = UITestID.movieCard(id)
        let predicate = NSPredicate(format: "identifier == %@", identifier)
        let match = app.descendants(matching: .any).matching(predicate).firstMatch
        return match.exists ? match : nil
    }

    func searchField(file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
        let field = app.searchFields[UITestID.searchField]
        if field.waitForExistence(timeout: 3) {
            return field
        }
        let fallback = app.searchFields.firstMatch
        XCTAssertTrue(fallback.waitForExistence(timeout: 8), file: file, line: line)
        return fallback
    }

    func clearSearchField(file: StaticString = #filePath, line: UInt = #line) {
        let field = searchField(file: file, line: line)
        field.tap()
        if field.buttons["Clear text"].waitForExistence(timeout: 2) {
            field.buttons["Clear text"].tap()
            return
        }
        let current = (field.value as? String) ?? ""
        guard !current.isEmpty else { return }
        let delete = String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count)
        field.typeText(delete)
    }

    func submitSearch(_ query: String, file: StaticString = #filePath, line: UInt = #line) {
        let field = searchField(file: file, line: line)
        field.tap()
        field.typeText(query)
        // Return triggers `.onSubmit(of: .search)` → commitSearch + runQueryNow (persists recents).
        if app.keyboards.keys["return"].waitForExistence(timeout: 1) {
            app.keyboards.keys["return"].tap()
        } else if app.keyboards.buttons["Search"].waitForExistence(timeout: 2) {
            app.keyboards.buttons["Search"].tap()
        } else if app.keyboards.buttons["search"].waitForExistence(timeout: 1) {
            app.keyboards.buttons["search"].tap()
        } else {
            field.typeText("\n")
        }
    }

    func recentChip(_ query: String) -> XCUIElement {
        let identifier = UITestID.recentChip(query)
        let predicate = NSPredicate(format: "identifier == %@", identifier)
        let match = app.descendants(matching: .any).matching(predicate).firstMatch
        return match.exists ? match : app.buttons[identifier]
    }

    @discardableResult
    func waitForRecentChip(
        _ query: String,
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            let chip = recentChip(query)
            if chip.exists {
                return chip
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
        XCTFail(
            "Expected recent chip \(UITestID.recentChip(query)) after saving a search in this session",
            file: file,
            line: line
        )
        return app.buttons[UITestID.recentChip(query)]
    }

    func dismissSearchKeyboard(file: StaticString = #filePath, line: UInt = #line) {
        app.navigationBars["Search"].tap()
        if app.keyboards.count > 0 {
            app.navigationBars["Search"].tap()
        }
    }

    /// Recent chips sit in a scroll view; after search results the chip may exist but not be hittable until scrolled.
    func tapRecentChip(
        _ query: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        dismissSearchKeyboard(file: file, line: line)

        let chip = waitForRecentChip(query, file: file, line: line)

        let scroll = app.scrollViews[UITestID.searchRoot]
        if scroll.waitForExistence(timeout: 2) {
            var attempts = 0
            while !chip.isHittable && attempts < 8 {
                scroll.swipeDown()
                attempts += 1
            }
        }

        if chip.isHittable {
            chip.tap()
        } else {
            chip.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
    }
}
