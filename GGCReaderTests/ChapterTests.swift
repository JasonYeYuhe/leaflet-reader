import XCTest
@testable import GGCReader

final class ChapterTests: XCTestCase {

    // MARK: - contains(page:)

    func testContainsPageInMiddle() {
        let c = Chapter(name: "One", startPage: 10, endPage: 20)
        XCTAssertTrue(c.contains(page: 15))
    }

    func testContainsStartPage() {
        let c = Chapter(name: "One", startPage: 10, endPage: 20)
        XCTAssertTrue(c.contains(page: 10))
    }

    func testContainsEndPage() {
        let c = Chapter(name: "One", startPage: 10, endPage: 20)
        XCTAssertTrue(c.contains(page: 20))
    }

    func testContainsPageBelowRange() {
        let c = Chapter(name: "One", startPage: 10, endPage: 20)
        XCTAssertFalse(c.contains(page: 9))
    }

    func testContainsPageAboveRange() {
        let c = Chapter(name: "One", startPage: 10, endPage: 20)
        XCTAssertFalse(c.contains(page: 21))
    }

    func testContainsPageZeroInSinglePageChapter() {
        let c = Chapter(name: "Intro", startPage: 0, endPage: 0)
        XCTAssertTrue(c.contains(page: 0))
    }

    // MARK: - pageCount

    func testPageCountNormal() {
        let c = Chapter(name: "One", startPage: 1, endPage: 10)
        XCTAssertEqual(c.pageCount, 10)
    }

    func testPageCountSinglePage() {
        let c = Chapter(name: "One", startPage: 5, endPage: 5)
        XCTAssertEqual(c.pageCount, 1)
    }

    func testPageCountInvalidRangeReturnsZero() {
        let c = Chapter(name: "Bad", startPage: 20, endPage: 10)
        XCTAssertEqual(c.pageCount, 0)
    }

    func testPageCountLargeRange() {
        let c = Chapter(name: "Tome", startPage: 1, endPage: 1000)
        XCTAssertEqual(c.pageCount, 1000)
    }

    // MARK: - sortOrder

    func testDefaultSortOrderIsZero() {
        let c = Chapter(name: "One", startPage: 1, endPage: 10)
        XCTAssertEqual(c.sortOrder, 0)
    }

    func testCustomSortOrder() {
        let c = Chapter(name: "Two", startPage: 11, endPage: 20, sortOrder: 1)
        XCTAssertEqual(c.sortOrder, 1)
    }
}
