import XCTest
@testable import GGCReader

final class ChallengeTypeTests: XCTestCase {

    // MARK: - allCases

    func testAllCasesCount() {
        XCTAssertEqual(ChallengeType.allCases.count, 4)
    }

    // MARK: - rawValue

    func testRawValueBooksCount() {
        XCTAssertEqual(ChallengeType.booksCount.rawValue, "booksCount")
    }

    func testRawValuePagesCount() {
        XCTAssertEqual(ChallengeType.pagesCount.rawValue, "pagesCount")
    }

    func testRawValueStreakDays() {
        XCTAssertEqual(ChallengeType.streakDays.rawValue, "streakDays")
    }

    func testRawValueReadingDays() {
        XCTAssertEqual(ChallengeType.readingDays.rawValue, "readingDays")
    }

    // MARK: - icon

    func testIconBooksCount() {
        XCTAssertEqual(ChallengeType.booksCount.icon, "book.closed.fill")
    }

    func testIconPagesCount() {
        XCTAssertEqual(ChallengeType.pagesCount.icon, "doc.text.fill")
    }

    func testIconStreakDays() {
        XCTAssertEqual(ChallengeType.streakDays.icon, "flame.fill")
    }

    func testIconReadingDays() {
        XCTAssertEqual(ChallengeType.readingDays.icon, "calendar")
    }

    // MARK: - unitName (non-empty, distinct where appropriate)

    func testUnitNameBooksCountNonEmpty() {
        XCTAssertFalse(ChallengeType.booksCount.unitName.isEmpty)
    }

    func testUnitNamePagesCountNonEmpty() {
        XCTAssertFalse(ChallengeType.pagesCount.unitName.isEmpty)
    }

    func testUnitNameStreakAndReadingDaysSame() {
        XCTAssertEqual(ChallengeType.streakDays.unitName, ChallengeType.readingDays.unitName)
    }

    func testUnitNameBooksCountDiffersFromPagesCount() {
        XCTAssertNotEqual(ChallengeType.booksCount.unitName, ChallengeType.pagesCount.unitName)
    }

    // MARK: - ReadingChallenge.color

    func testChallengeColorDefaultIsBlue() {
        let c = ReadingChallenge(title: "Test", type: .booksCount, target: 5,
                                 endDate: Date().addingTimeInterval(86400))
        XCTAssertEqual(c.color, .blue)
    }

    func testChallengeColorSetInInit() {
        let c = ReadingChallenge(title: "Test", type: .booksCount, target: 5,
                                 endDate: Date().addingTimeInterval(86400), color: .red)
        XCTAssertEqual(c.color, .red)
    }

    func testChallengeColorInvalidNameDefaultsToBlue() {
        let c = ReadingChallenge(title: "Test", type: .booksCount, target: 5,
                                 endDate: Date().addingTimeInterval(86400))
        c.colorName = "notacolor"
        XCTAssertEqual(c.color, .blue)
    }
}
