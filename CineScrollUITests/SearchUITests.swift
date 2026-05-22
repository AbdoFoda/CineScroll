import XCTest

final class SearchUITests: CineScrollUITestCase {
    override func setUp() async throws {
        try await super.setUp()
        openSearchTab()
    }

    func testSearchEmptyStateVisible() throws {
        XCTAssertTrue(app.staticTexts["Search movies"].waitForExistence(timeout: 4))
    }

    func testSearchFindsMatrix() throws {
        submitSearch("Matrix")
        _ = waitForMovieCard(UITestID.matrixMovieID)
    }

    func testSearchNoResultsState() throws {
        submitSearch("zzzznotamoviezzzz")
        XCTAssertTrue(app.staticTexts["No matches"].waitForExistence(timeout: 6))
    }

    func testSearchRecentChipRerunsQuery() throws {
        
        submitSearch("Matrix")
        _ = waitForMovieCard(UITestID.matrixMovieID)

        clearSearchField()
        _ = waitForRecentChip("Matrix")
        tapRecentChip("Matrix")
        _ = waitForMovieCard(UITestID.matrixMovieID)
    }

    func testOpenMovieDetailFromSearchResults() throws {
        submitSearch("Inception")
        waitForMovieCard(102).tap()

        waitFor(app.navigationBars["Inception"])
        XCTAssertTrue(app.staticTexts["Inception"].waitForExistence(timeout: 4))
    }
}
