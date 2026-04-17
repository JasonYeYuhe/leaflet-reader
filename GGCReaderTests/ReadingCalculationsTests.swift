import XCTest
@testable import GGCReader

final class ReadingCalculationsTests: XCTestCase {

    // MARK: - percentage

    func testPercentageZeroPages() {
        XCTAssertEqual(ReadingCalculations.percentage(currentPage: 0, totalPages: 0), 0.0)
    }

    func testPercentageZeroProgress() {
        XCTAssertEqual(ReadingCalculations.percentage(currentPage: 0, totalPages: 100), 0.0)
    }

    func testPercentageHalfway() {
        XCTAssertEqual(ReadingCalculations.percentage(currentPage: 50, totalPages: 100), 0.5)
    }

    func testPercentageComplete() {
        XCTAssertEqual(ReadingCalculations.percentage(currentPage: 100, totalPages: 100), 1.0)
    }

    func testPercentageClamped() {
        XCTAssertEqual(ReadingCalculations.percentage(currentPage: 150, totalPages: 100), 1.0)
    }

    // MARK: - pagesRemaining

    func testPagesRemainingNormal() {
        XCTAssertEqual(ReadingCalculations.pagesRemaining(currentPage: 30, totalPages: 100), 70)
    }

    func testPagesRemainingAtEnd() {
        XCTAssertEqual(ReadingCalculations.pagesRemaining(currentPage: 100, totalPages: 100), 0)
    }

    func testPagesRemainingNoNegative() {
        XCTAssertEqual(ReadingCalculations.pagesRemaining(currentPage: 120, totalPages: 100), 0)
    }
}
