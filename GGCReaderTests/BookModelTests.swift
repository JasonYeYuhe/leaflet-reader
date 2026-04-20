import XCTest
@testable import GGCReader

final class BookModelTests: XCTestCase {

    // MARK: - formattedProgress (physical / ebook)

    func testFormattedProgressEbook() {
        let b = Book(title: "Test", author: "Author", totalPages: 200, bookType: .ebook)
        b.currentPage = 30
        XCTAssertEqual(b.formattedProgress, "30/200")
    }

    func testFormattedProgressEbookZeroStart() {
        let b = Book(title: "Test", author: "Author", totalPages: 300, bookType: .ebook)
        XCTAssertEqual(b.formattedProgress, "0/300")
    }

    // MARK: - formattedRemaining (ebook)

    func testFormattedRemainingEbook() {
        let b = Book(title: "Test", author: "Author", totalPages: 200, bookType: .ebook)
        b.currentPage = 130
        XCTAssertEqual(b.formattedRemaining, "70 pages left")
    }

    func testFormattedRemainingEbookAtEnd() {
        let b = Book(title: "Test", author: "Author", totalPages: 100, bookType: .ebook)
        b.currentPage = 100
        XCTAssertEqual(b.formattedRemaining, "0 pages left")
    }

    func testFormattedRemainingEbookMatchesPhysical() {
        let physical = Book(title: "Test", author: "Author", totalPages: 200)
        let ebook = Book(title: "Test", author: "Author", totalPages: 200, bookType: .ebook)
        physical.currentPage = 80
        ebook.currentPage = 80
        XCTAssertEqual(physical.formattedRemaining, ebook.formattedRemaining)
    }

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

    func testFormattedRemainingAudiobookAtEnd() {
        let b = Book(title: "Test", author: "Author", totalPages: 180, bookType: .audiobook)
        b.currentPage = 180  // remaining = 0 → "0m left"
        XCTAssertEqual(b.formattedRemaining, "0m left")
    }

    func testFormattedRemainingAudiobookExactlyOneHour() {
        let b = Book(title: "Test", author: "Author", totalPages: 240, bookType: .audiobook)
        b.currentPage = 180  // remaining = 60 → "1h 0m left"
        XCTAssertEqual(b.formattedRemaining, "1h 0m left")
    }

    func testFormattedRemainingAudiobookLargeValue() {
        let b = Book(title: "Test", author: "Author", totalPages: 420, bookType: .audiobook)
        b.currentPage = 0  // remaining = 420 → 7h 0m left
        XCTAssertEqual(b.formattedRemaining, "7h 0m left")
    }

    // MARK: - formattedProgress audiobook start

    func testFormattedProgressAudiobookAtStart() {
        let b = Book(title: "Test", author: "Author", totalPages: 120, bookType: .audiobook)
        // currentPage defaults to 0 → "0m"
        XCTAssertEqual(b.formattedProgress, "0m")
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

    // MARK: - progressPercentage

    func testProgressPercentageZeroTotalPages() {
        let b = Book(title: "Test", author: "Author", totalPages: 0)
        XCTAssertEqual(b.progressPercentage, 0.0)
    }

    func testProgressPercentageZeroProgress() {
        let b = Book(title: "Test", author: "Author", totalPages: 200)
        XCTAssertEqual(b.progressPercentage, 0.0)
    }

    func testProgressPercentageHalfway() {
        let b = Book(title: "Test", author: "Author", totalPages: 200)
        b.currentPage = 100
        XCTAssertEqual(b.progressPercentage, 0.5, accuracy: 0.001)
    }

    func testProgressPercentageComplete() {
        let b = Book(title: "Test", author: "Author", totalPages: 100)
        b.currentPage = 100
        XCTAssertEqual(b.progressPercentage, 1.0, accuracy: 0.001)
    }

    func testProgressPercentageClampedAtOne() {
        let b = Book(title: "Test", author: "Author", totalPages: 100)
        b.currentPage = 150
        XCTAssertEqual(b.progressPercentage, 1.0, accuracy: 0.001)
    }

    // MARK: - pagesRemaining

    func testPagesRemainingNormal() {
        let b = Book(title: "Test", author: "Author", totalPages: 300)
        b.currentPage = 100
        XCTAssertEqual(b.pagesRemaining, 200)
    }

    func testPagesRemainingAtEnd() {
        let b = Book(title: "Test", author: "Author", totalPages: 100)
        b.currentPage = 100
        XCTAssertEqual(b.pagesRemaining, 0)
    }

    func testPagesRemainingNoNegative() {
        let b = Book(title: "Test", author: "Author", totalPages: 100)
        b.currentPage = 120
        XCTAssertEqual(b.pagesRemaining, 0)
    }

    // MARK: - currentChapter

    func testCurrentChapterEmptyReturnsNil() {
        let b = Book(title: "Test", author: "Author", totalPages: 200)
        b.currentPage = 50
        XCTAssertNil(b.currentChapter)
    }

    func testCurrentChapterSelectsCurrentByStartPage() {
        let b = Book(title: "Test", author: "Author", totalPages: 300)
        let ch1 = Chapter(name: "Part I", startPage: 1, endPage: 100)
        let ch2 = Chapter(name: "Part II", startPage: 101, endPage: 200)
        let ch3 = Chapter(name: "Part III", startPage: 201, endPage: 300)
        b.chapters = [ch1, ch2, ch3]
        b.currentPage = 150
        XCTAssertEqual(b.currentChapter?.name, "Part II")
    }

    func testCurrentChapterPageBeforeFirstReturnsNil() {
        let b = Book(title: "Test", author: "Author", totalPages: 200)
        let ch = Chapter(name: "Ch 1", startPage: 10, endPage: 200)
        b.chapters = [ch]
        b.currentPage = 5
        XCTAssertNil(b.currentChapter)
    }

    // MARK: - bookType get/set

    func testBookTypeDefaultIsPhysical() {
        let b = Book(title: "Test", author: "Author", totalPages: 100)
        XCTAssertEqual(b.bookType, .physical)
    }

    func testBookTypeSetterUpdatesRaw() {
        let b = Book(title: "Test", author: "Author", totalPages: 100)
        b.bookType = .audiobook
        XCTAssertEqual(b.bookTypeRaw, BookType.audiobook.rawValue)
        XCTAssertEqual(b.bookType, .audiobook)
    }

    // MARK: - init optional field defaults

    func testRatingDefaultsToNil() {
        let b = Book(title: "Test", author: "Author", totalPages: 100)
        XCTAssertNil(b.rating)
    }

    func testReviewDefaultsToNil() {
        let b = Book(title: "Test", author: "Author", totalPages: 100)
        XCTAssertNil(b.review)
    }

    func testDateFinishedDefaultsToNil() {
        let b = Book(title: "Test", author: "Author", totalPages: 100)
        XCTAssertNil(b.dateFinished)
    }

    func testLastReadDateDefaultsToNil() {
        let b = Book(title: "Test", author: "Author", totalPages: 100)
        XCTAssertNil(b.lastReadDate)
    }

    func testISBNDefaultsToEmpty() {
        let b = Book(title: "Test", author: "Author", totalPages: 100)
        XCTAssertEqual(b.isbn, "")
    }

    func testPublisherDefaultsToEmpty() {
        let b = Book(title: "Test", author: "Author", totalPages: 100)
        XCTAssertEqual(b.publisher, "")
    }

    func testGenreDefaultsToEmpty() {
        let b = Book(title: "Test", author: "Author", totalPages: 100)
        XCTAssertEqual(b.genre, "")
    }

    // MARK: - coverColor get/set

    func testCoverColorDefaultIsBlue() {
        let b = Book(title: "Test", author: "Author", totalPages: 100)
        XCTAssertEqual(b.coverColor, .blue)
    }

    func testCoverColorSetterUpdatesName() {
        let b = Book(title: "Test", author: "Author", totalPages: 100)
        b.coverColor = .red
        XCTAssertEqual(b.coverColorName, CoverColor.red.rawValue)
        XCTAssertEqual(b.coverColor, .red)
    }

    // MARK: - init field storage

    func testTitleStoredInInit() {
        let b = Book(title: "Dune", author: "Herbert", totalPages: 604)
        XCTAssertEqual(b.title, "Dune")
    }

    func testAuthorStoredInInit() {
        let b = Book(title: "Dune", author: "Frank Herbert", totalPages: 604)
        XCTAssertEqual(b.author, "Frank Herbert")
    }

    func testTotalPagesStoredInInit() {
        let b = Book(title: "Dune", author: "Herbert", totalPages: 604)
        XCTAssertEqual(b.totalPages, 604)
    }

    func testIDIsAssignedOnInit() {
        let b = Book(title: "Test", author: "Author", totalPages: 100)
        XCTAssertNotNil(b.id)
    }

    func testTwoInstancesHaveDifferentIDs() {
        let a = Book(title: "A", author: "Author", totalPages: 100)
        let b = Book(title: "B", author: "Author", totalPages: 100)
        XCTAssertNotEqual(a.id, b.id)
    }

    func testDateAddedIsRecent() {
        let before = Date()
        let book = Book(title: "Test", author: "Author", totalPages: 100)
        let after = Date()
        XCTAssertGreaterThanOrEqual(book.dateAdded, before)
        XCTAssertLessThanOrEqual(book.dateAdded, after)
    }
}
