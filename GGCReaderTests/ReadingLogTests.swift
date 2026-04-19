import XCTest
@testable import GGCReader

final class ReadingLogTests: XCTestCase {

    // MARK: - pagesRead

    func testPagesReadNormal() {
        let log = ReadingLog(fromPage: 50, toPage: 100)
        XCTAssertEqual(log.pagesRead, 50)
    }

    func testPagesReadSinglePage() {
        let log = ReadingLog(fromPage: 99, toPage: 100)
        XCTAssertEqual(log.pagesRead, 1)
    }

    func testPagesReadZeroWhenEqual() {
        let log = ReadingLog(fromPage: 50, toPage: 50)
        XCTAssertEqual(log.pagesRead, 0)
    }

    func testPagesReadZeroWhenReversed() {
        // max(toPage - fromPage, 0) guards against negative values
        let log = ReadingLog(fromPage: 100, toPage: 50)
        XCTAssertEqual(log.pagesRead, 0)
    }

    func testPagesReadLargeRange() {
        let log = ReadingLog(fromPage: 0, toPage: 500)
        XCTAssertEqual(log.pagesRead, 500)
    }

    // MARK: - stored fields

    func testFromPageStoredCorrectly() {
        let log = ReadingLog(fromPage: 42, toPage: 100)
        XCTAssertEqual(log.fromPage, 42)
    }

    func testToPageStoredCorrectly() {
        let log = ReadingLog(fromPage: 42, toPage: 100)
        XCTAssertEqual(log.toPage, 100)
    }

    // MARK: - id + date

    func testIDIsAssigned() {
        let log = ReadingLog(fromPage: 0, toPage: 10)
        XCTAssertNotNil(log.id)
    }

    func testTwoInstancesHaveDifferentIDs() {
        let a = ReadingLog(fromPage: 0, toPage: 10)
        let b = ReadingLog(fromPage: 0, toPage: 10)
        XCTAssertNotEqual(a.id, b.id)
    }

    func testDateIsCurrentTime() {
        let before = Date()
        let log = ReadingLog(fromPage: 0, toPage: 10)
        let after = Date()
        XCTAssertGreaterThanOrEqual(log.date, before)
        XCTAssertLessThanOrEqual(log.date, after)
    }
}
