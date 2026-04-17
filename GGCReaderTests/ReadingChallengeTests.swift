import XCTest
@testable import GGCReader

final class ReadingChallengeTests: XCTestCase {

    private func futureDate() -> Date { Date().addingTimeInterval(86400 * 30) }
    private func pastDate() -> Date { Date().addingTimeInterval(-86400) }

    // MARK: - isActive

    func testIsActiveNotCompletedFutureEnd() {
        let c = ReadingChallenge(title: "Test", type: .booksCount, target: 10, endDate: futureDate())
        XCTAssertTrue(c.isActive)
    }

    func testIsActiveCompletedReturnsFalse() {
        let c = ReadingChallenge(title: "Test", type: .booksCount, target: 10, endDate: futureDate())
        c.isCompleted = true
        XCTAssertFalse(c.isActive)
    }

    func testIsActivePastEndReturnsFalse() {
        let c = ReadingChallenge(title: "Test", type: .booksCount, target: 10, endDate: pastDate())
        XCTAssertFalse(c.isActive)
    }

    // MARK: - isExpired

    func testIsExpiredNotCompletedPastEnd() {
        let c = ReadingChallenge(title: "Test", type: .booksCount, target: 10, endDate: pastDate())
        XCTAssertTrue(c.isExpired)
    }

    func testIsExpiredCompletedReturnsFalse() {
        let c = ReadingChallenge(title: "Test", type: .booksCount, target: 10, endDate: pastDate())
        c.isCompleted = true
        XCTAssertFalse(c.isExpired)
    }

    func testIsExpiredFutureEndReturnsFalse() {
        let c = ReadingChallenge(title: "Test", type: .booksCount, target: 10, endDate: futureDate())
        XCTAssertFalse(c.isExpired)
    }

    // MARK: - daysRemaining

    func testDaysRemainingPastDateIsZero() {
        let c = ReadingChallenge(title: "Test", type: .booksCount, target: 10, endDate: pastDate())
        XCTAssertEqual(c.daysRemaining, 0)
    }

    func testDaysRemainingFutureIsPositive() {
        let c = ReadingChallenge(title: "Test", type: .booksCount, target: 10, endDate: futureDate())
        XCTAssertGreaterThan(c.daysRemaining, 0)
    }

    // MARK: - challengeType

    func testChallengeTypeRoundtrip() {
        let c = ReadingChallenge(title: "Test", type: .pagesCount, target: 500, endDate: futureDate())
        XCTAssertEqual(c.challengeType, .pagesCount)
    }

    func testChallengeTypeInvalidRawDefaultsToBooksCount() {
        let c = ReadingChallenge(title: "Test", type: .streakDays, target: 30, endDate: futureDate())
        c.challengeTypeRaw = "invalid"
        XCTAssertEqual(c.challengeType, .booksCount)
    }
}
