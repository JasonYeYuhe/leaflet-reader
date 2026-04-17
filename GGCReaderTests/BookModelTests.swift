import XCTest
@testable import GGCReader

final class BookModelTests: XCTestCase {

    // MARK: - formattedProgress (physical / ebook)

    func testFormattedProgressPhysical() {
        let b = Book(title: "Test", author: "Author", totalPages: 200)
        b.currentPage = 30
        XCTAssertEqual(b.formattedProgress, "30/200")
    }

    func testFormattedProgressPhysicalZeroStart() {
        let b = Book(title: "Test", author: "Author", totalPages: 300)
        XCTAssertEqual(b.formattedProgress, "0/300")
    }

    // MARK: - formattedProgress (audiobook)

    func testFormattedProgressAudiobookMinutesOnly() {
        let b = Book(title: "Test", author: "Author", totalPages: 120, bookType: .audiobook)
        b.currentPage = 45
        XCTAssertEqual(b.formattedProgress, "45m")
    }

    func testFormattedProgressAudiobookHoursAndMinutes() {
        let b = Book(title: "Test", author: "Author", totalPages: 300, bookType: .audiobook)
        b.currentPage = 150  // 2h 30m
        XCTAssertEqual(b.formattedProgress, "2h 30m")
    }

    func testFormattedProgressAudiobookExactHour() {
        let b = Book(title: "Test", author: "Author", totalPages: 300, bookType: .audiobook)
        b.currentPage = 60  // 1h 0m
        XCTAssertEqual(b.formattedProgress, "1h 0m")
    }

    // MARK: - formattedRemaining

    func testFormattedRemainingPhysical() {
        let b = Book(title: "Test", author: "Author", totalPages: 200)
        b.currentPage = 130
        XCTAssertEqual(b.formattedRemaining, "70 pages left")
    }

    func testFormattedRemainingAudiobookMinutesOnly() {
        let b = Book(title: "Test", author: "Author", totalPages: 100, bookType: .audiobook)
        b.currentPage = 85
        XCTAssertEqual(b.formattedRemaining, "15m left")
    }

    func testFormattedRemainingAudiobookHoursAndMinutes() {
        let b = Book(title: "Test", author: "Author", totalPages: 300, bookType: .audiobook)
        b.currentPage = 150  // remaining = 150 → 2h 30m
        XCTAssertEqual(b.formattedRemaining, "2h 30m left")
    }

    // MARK: - isFinished

    func testIsFinishedAtLastPage() {
        let b = Book(title: "Test", author: "Author", totalPages: 200)
        b.currentPage = 200
        XCTAssertTrue(b.isFinished)
    }

    func testIsFinishedWhenIncomplete() {
        let b = Book(title: "Test", author: "Author", totalPages: 200)
        b.currentPage = 100
        XCTAssertFalse(b.isFinished)
    }

    func testIsFinishedZeroTotalPages() {
        let b = Book(title: "Test", author: "Author", totalPages: 0)
        XCTAssertFalse(b.isFinished)
    }

    func testIsFinishedPastEndPage() {
        let b = Book(title: "Test", author: "Author", totalPages: 100)
        b.currentPage = 120
        XCTAssertTrue(b.isFinished)
    }
}
