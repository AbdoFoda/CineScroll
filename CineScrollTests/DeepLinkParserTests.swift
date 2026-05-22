import XCTest

@testable import CineScroll

final class DeepLinkParserTests: XCTestCase {
    func testParsesValidMovieDeepLink() {
        let url = URL(string: "cineScroll://movie/101")!
        XCTAssertEqual(DeepLinkParser.movieID(from: url), 101)
    }

    func testParsesMovieDeepLinkWithTrailingSlash() {
        let url = URL(string: "cineScroll://movie/42/")!
        XCTAssertEqual(DeepLinkParser.movieID(from: url), 42)
    }

    func testSchemeIsCaseInsensitive() {
        let url = URL(string: "CINESCROLL://movie/7")!
        XCTAssertEqual(DeepLinkParser.movieID(from: url), 7)
    }

    func testHostIsCaseInsensitive() {
        let url = URL(string: "cineScroll://MOVIE/9")!
        XCTAssertEqual(DeepLinkParser.movieID(from: url), 9)
    }

    func testRejectsWrongScheme() {
        let url = URL(string: "https://movie/101")!
        XCTAssertNil(DeepLinkParser.movieID(from: url))
    }

    func testRejectsWrongHost() {
        let url = URL(string: "cineScroll://search/101")!
        XCTAssertNil(DeepLinkParser.movieID(from: url))
    }

    func testRejectsEmptyPath() {
        let url = URL(string: "cineScroll://movie/")!
        XCTAssertNil(DeepLinkParser.movieID(from: url))
    }

    func testRejectsNonNumericPath() {
        let url = URL(string: "cineScroll://movie/abc")!
        XCTAssertNil(DeepLinkParser.movieID(from: url))
    }
}
