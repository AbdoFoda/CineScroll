import XCTest
@testable import CineScroll

/// Tests `UserDefaultsRecentSearchStore` with an isolated `UserDefaults` suite
final class UserDefaultsRecentSearchStoreTests: XCTestCase {

    private var store: UserDefaultsRecentSearchStore!
    private var isolatedDefaults: UserDefaults!
    private let suiteName = "com.cinescroll.tests.recentsearch"

    override func setUp() {
        super.setUp()
        UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
        isolatedDefaults = UserDefaults(suiteName: suiteName)
        store = UserDefaultsRecentSearchStore(defaults: isolatedDefaults)
    }

    override func tearDown() {
        UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
        store = nil
        isolatedDefaults = nil
        super.tearDown()
    }

    // MARK: - Initial state

    func testLoadQueriesReturnsEmptyArrayInitially() async {
        let result = await store.loadQueries()
        XCTAssertEqual(result, [])
    }

    // MARK: - Save / Load round-trip

    func testSaveAndLoadRoundTrip() async {
        await store.saveQueries(["Inception", "Matrix", "Interstellar"])
        let result = await store.loadQueries()
        XCTAssertEqual(result, ["Inception", "Matrix", "Interstellar"])
    }

    func testOrderIsPreserved() async {
        let queries = ["C", "B", "A"]
        await store.saveQueries(queries)
        let result = await store.loadQueries()
        XCTAssertEqual(result, queries)
    }

    func testSavingEmptyArrayClearsStore() async {
        await store.saveQueries(["Something"])
        await store.saveQueries([])
        let result = await store.loadQueries()
        XCTAssertEqual(result, [])
    }

    func testOverwriteReplacesAllValues() async {
        await store.saveQueries(["Old1", "Old2"])
        await store.saveQueries(["New"])
        let result = await store.loadQueries()
        XCTAssertEqual(result, ["New"])
    }

    func testSingleQueryPersists() async {
        await store.saveQueries(["Blade Runner"])
        let result = await store.loadQueries()
        XCTAssertEqual(result.first, "Blade Runner")
        XCTAssertEqual(result.count, 1)
    }

    // MARK: - Isolation

    func testStoreIsolatedFromDefaultSuite() async {
        let defaultStore = UserDefaultsRecentSearchStore()
        let prevDefault = await defaultStore.loadQueries()
        await store.saveQueries(["IsolatedQuery"])
        let afterWrite = await defaultStore.loadQueries()
        XCTAssertEqual(afterWrite, prevDefault, "Isolated suite must not leak into default suite")
    }

    func testTwoSeparateSuitesAreIndependent() async {
        let suiteName2 = "com.cinescroll.tests.recentsearch2"
        UserDefaults(suiteName: suiteName2)?.removePersistentDomain(forName: suiteName2)
        let defaults2 = UserDefaults(suiteName: suiteName2)!
        let store2 = UserDefaultsRecentSearchStore(defaults: defaults2)
        defer { UserDefaults(suiteName: suiteName2)?.removePersistentDomain(forName: suiteName2) }

        await store.saveQueries(["Suite1Query"])
        await store2.saveQueries(["Suite2Query"])

        let result1 = await store.loadQueries()
        let result2 = await store2.loadQueries()
        XCTAssertEqual(result1, ["Suite1Query"])
        XCTAssertEqual(result2, ["Suite2Query"])
    }

    // MARK: - InMemoryRecentSearchStore

    func testInMemoryStoreInitiallyEmpty() async {
        let inMem = InMemoryRecentSearchStore()
        let result = await inMem.loadQueries()
        XCTAssertEqual(result, [])
    }

    func testInMemoryStoreRoundTrip() async {
        let inMem = InMemoryRecentSearchStore()
        await inMem.saveQueries(["Matrix", "Inception"])
        let result = await inMem.loadQueries()
        XCTAssertEqual(result, ["Matrix", "Inception"])
    }

    func testInMemoryStoreSavingEmptyClears() async {
        let inMem = InMemoryRecentSearchStore()
        await inMem.saveQueries(["Matrix"])
        await inMem.saveQueries([])
        let result = await inMem.loadQueries()
        XCTAssertEqual(result, [])
    }
}
