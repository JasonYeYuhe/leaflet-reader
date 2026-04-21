import XCTest
@testable import GGCReader

final class ChallengeProgressTests: XCTestCase {

    // Helpers
    private let cal = Calendar.current

    private func date(daysAgo: Int) -> Date {
        cal.startOfDay(for: cal.date(byAdding: .day, value: -daysAgo, to: Date())!)
    }

    private func log(fromPage: Int, toPage: Int, daysAgo: Int) -> ReadingLog {
        let l = ReadingLog(fromPage: fromPage, toPage: toPage)
        l.date = date(daysAgo: daysAgo)
        return l
    }

    private func challenge(type: ChallengeType, startDaysAgo: Int = 30, endDaysFromNow: Int = 30) -> ReadingChallenge {
        let end = cal.date(byAdding: .day, value: endDaysFromNow, to: Date())!
        let c = ReadingChallenge(title: "Test", type: type, target: 99, endDate: end, color: .blue)
        c.startDate = date(daysAgo: startDaysAgo)
        return c
    }

    // MARK: - booksCount

    func testBooksCountFinishedInRange() {
        let c = challenge(type: .booksCount, startDaysAgo: 10, endDaysFromNow: 10)
        c.startDate = date(daysAgo: 10)
        let book = Book(title: "Dune", author: "Herbert", totalPages: 100)
        book.currentPage = 100
        book.dateFinished = date(daysAgo: 5)
        XCTAssertEqual(ReadingCalculations.challengeProgress(challenge: c, logs: [], books: [book]), 1)
    }

    func testBooksCountFinishedBeforeStart() {
        let c = challenge(type: .booksCount, startDaysAgo: 5, endDaysFromNow: 10)
        c.startDate = date(daysAgo: 5)
        let book = Book(title: "Dune", author: "Herbert", totalPages: 100)
        book.currentPage = 100
        book.dateFinished = date(daysAgo: 10)  // finished before challenge started
        XCTAssertEqual(ReadingCalculations.challengeProgress(challenge: c, logs: [], books: [book]), 0)
    }

    func testBooksCountUnfinishedBookNotCounted() {
        let c = challenge(type: .booksCount)
        let book = Book(title: "Dune", author: "Herbert", totalPages: 100)
        book.currentPage = 50
        XCTAssertEqual(ReadingCalculations.challengeProgress(challenge: c, logs: [], books: [book]), 0)
    }

    func testBooksCountMultipleBooksInRange() {
        let c = challenge(type: .booksCount, startDaysAgo: 20, endDaysFromNow: 10)
        c.startDate = date(daysAgo: 20)
        let b1 = Book(title: "A", author: "Auth", totalPages: 100)
        b1.currentPage = 100; b1.dateFinished = date(daysAgo: 15)
        let b2 = Book(title: "B", author: "Auth", totalPages: 200)
        b2.currentPage = 200; b2.dateFinished = date(daysAgo: 3)
        let b3 = Book(title: "C", author: "Auth", totalPages: 50)
        b3.currentPage = 30  // not finished
        XCTAssertEqual(ReadingCalculations.challengeProgress(challenge: c, logs: [], books: [b1, b2, b3]), 2)
    }

    // MARK: - pagesCount

    func testPagesCountLogsInRange() {
        let c = challenge(type: .pagesCount, startDaysAgo: 10, endDaysFromNow: 10)
        c.startDate = date(daysAgo: 10)
        let logs = [log(fromPage: 0, toPage: 50, daysAgo: 5), log(fromPage: 50, toPage: 80, daysAgo: 3)]
        XCTAssertEqual(ReadingCalculations.challengeProgress(challenge: c, logs: logs, books: []), 80)
    }

    func testPagesCountExcludesLogsBeforeStart() {
        let c = challenge(type: .pagesCount, startDaysAgo: 5, endDaysFromNow: 10)
        c.startDate = date(daysAgo: 5)
        let logs = [log(fromPage: 0, toPage: 100, daysAgo: 10)]  // before challenge start
        XCTAssertEqual(ReadingCalculations.challengeProgress(challenge: c, logs: logs, books: []), 0)
    }

    func testPagesCountNoLogs() {
        let c = challenge(type: .pagesCount)
        XCTAssertEqual(ReadingCalculations.challengeProgress(challenge: c, logs: [], books: []), 0)
    }

    // MARK: - streakDays

    func testStreakDaysThreeConsecutiveDays() {
        let c = challenge(type: .streakDays, startDaysAgo: 10, endDaysFromNow: 10)
        c.startDate = date(daysAgo: 10)
        let logs = [
            log(fromPage: 0, toPage: 10, daysAgo: 4),
            log(fromPage: 0, toPage: 10, daysAgo: 3),
            log(fromPage: 0, toPage: 10, daysAgo: 2)
        ]
        XCTAssertEqual(ReadingCalculations.challengeProgress(challenge: c, logs: logs, books: []), 3)
    }

    func testStreakDaysResetsByGap() {
        let c = challenge(type: .streakDays, startDaysAgo: 10, endDaysFromNow: 10)
        c.startDate = date(daysAgo: 10)
        // 2-day streak, gap day 5 ago, then 1-day streak
        let logs = [
            log(fromPage: 0, toPage: 10, daysAgo: 7),
            log(fromPage: 0, toPage: 10, daysAgo: 6),
            // gap at daysAgo 5
            log(fromPage: 0, toPage: 10, daysAgo: 4)
        ]
        // best streak = 2
        XCTAssertEqual(ReadingCalculations.challengeProgress(challenge: c, logs: logs, books: []), 2)
    }

    func testStreakDaysNoLogs() {
        let c = challenge(type: .streakDays)
        XCTAssertEqual(ReadingCalculations.challengeProgress(challenge: c, logs: [], books: []), 0)
    }

    func testStreakDaysTwoLogsOnSameDayCountAsOne() {
        let c = challenge(type: .streakDays, startDaysAgo: 5, endDaysFromNow: 5)
        c.startDate = date(daysAgo: 5)
        // Two logs on the same day — should count as a single streak day
        let logs = [
            log(fromPage: 0, toPage: 30, daysAgo: 2),
            log(fromPage: 30, toPage: 60, daysAgo: 2)
        ]
        XCTAssertEqual(ReadingCalculations.challengeProgress(challenge: c, logs: logs, books: []), 1)
    }

    // MARK: - readingDays

    func testReadingDaysTwoLogsOnSameDayCountAsOne() {
        let c = challenge(type: .readingDays)
        let logs = [log(fromPage: 0, toPage: 30, daysAgo: 2), log(fromPage: 30, toPage: 60, daysAgo: 2)]
        XCTAssertEqual(ReadingCalculations.challengeProgress(challenge: c, logs: logs, books: []), 1)
    }

    func testReadingDaysDifferentDays() {
        let c = challenge(type: .readingDays, startDaysAgo: 10, endDaysFromNow: 10)
        c.startDate = date(daysAgo: 10)
        let logs = [
            log(fromPage: 0, toPage: 10, daysAgo: 4),
            log(fromPage: 0, toPage: 10, daysAgo: 3),
            log(fromPage: 0, toPage: 10, daysAgo: 1)
        ]
        XCTAssertEqual(ReadingCalculations.challengeProgress(challenge: c, logs: logs, books: []), 3)
    }

    func testReadingDaysNoLogs() {
        let c = challenge(type: .readingDays)
        XCTAssertEqual(ReadingCalculations.challengeProgress(challenge: c, logs: [], books: []), 0)
    }

    // MARK: - today clamping

    func testEffectiveEndClampedToEndDateWhenChallengeExpired() {
        // Challenge ended 5 days ago — today is past endDate, so effectiveEnd = endDate
        let endDate = date(daysAgo: 5)
        let c = ReadingChallenge(title: "Past", type: .pagesCount, target: 50,
                                  endDate: endDate, color: .blue)
        c.startDate = date(daysAgo: 15)
        // Log from 3 days ago — AFTER the challenge ended — should be excluded
        let logs = [log(fromPage: 0, toPage: 100, daysAgo: 3)]
        XCTAssertEqual(ReadingCalculations.challengeProgress(challenge: c, logs: logs, books: []), 0)
    }

    // MARK: - booksCount: date fallback paths

    func testBooksCountUsesLastReadDateWhenDateFinishedNil() {
        // dateFinished ?? lastReadDate ?? .distantFuture — lastReadDate branch
        let c = challenge(type: .booksCount, startDaysAgo: 10, endDaysFromNow: 10)
        c.startDate = date(daysAgo: 10)
        let book = Book(title: "Dune", author: "Herbert", totalPages: 100)
        book.currentPage = 100   // isFinished = true
        book.dateFinished = nil
        book.lastReadDate = date(daysAgo: 5)  // in range
        XCTAssertEqual(ReadingCalculations.challengeProgress(challenge: c, logs: [], books: [book]), 1)
    }

    func testBooksCountExcludesFinishedBookWithNoDateInfo() {
        // Both dateFinished and lastReadDate nil → .distantFuture used → > endDate → excluded
        let c = challenge(type: .booksCount, startDaysAgo: 10, endDaysFromNow: 10)
        c.startDate = date(daysAgo: 10)
        let book = Book(title: "Dune", author: "Herbert", totalPages: 100)
        book.currentPage = 100
        book.dateFinished = nil
        book.lastReadDate = nil   // distantFuture > endDate → not counted
        XCTAssertEqual(ReadingCalculations.challengeProgress(challenge: c, logs: [], books: [book]), 0)
    }

    // MARK: - pagesCount: boundary and future-start

    func testPagesCountLogOnExactStartDateIncluded() {
        // Logs on the exact start date satisfy `>= start` and must be counted
        let c = challenge(type: .pagesCount, startDaysAgo: 7, endDaysFromNow: 7)
        c.startDate = date(daysAgo: 7)
        let logOnStart = log(fromPage: 0, toPage: 40, daysAgo: 7)
        XCTAssertEqual(ReadingCalculations.challengeProgress(challenge: c, logs: [logOnStart], books: []), 40)
    }

    func testPagesCountFutureStartChallengeReturnsZero() {
        // Challenge starts tomorrow: effectiveEnd = today < start → no logs qualify
        let tomorrow = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: Date()))!
        let futureEnd = cal.date(byAdding: .day, value: 30, to: Date())!
        let c = ReadingChallenge(title: "Future", type: .pagesCount, target: 500, endDate: futureEnd)
        c.startDate = tomorrow
        let logs = [log(fromPage: 0, toPage: 100, daysAgo: 0)]  // today — before challenge
        XCTAssertEqual(ReadingCalculations.challengeProgress(challenge: c, logs: logs, books: []), 0)
    }

    // MARK: - readingDays: future-start

    func testReadingDaysFutureStartChallengeReturnsZero() {
        let tomorrow = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: Date()))!
        let futureEnd = cal.date(byAdding: .day, value: 30, to: Date())!
        let c = ReadingChallenge(title: "Future", type: .readingDays, target: 20, endDate: futureEnd)
        c.startDate = tomorrow
        let logs = [log(fromPage: 0, toPage: 50, daysAgo: 0)]
        XCTAssertEqual(ReadingCalculations.challengeProgress(challenge: c, logs: logs, books: []), 0)
    }

    // MARK: - readingDays: exact start-date boundary

    func testReadingDaysLogOnExactStartDateCounted() {
        // A log dated exactly on challenge.startDate must satisfy >= start and be counted
        let c = challenge(type: .readingDays, startDaysAgo: 10, endDaysFromNow: 10)
        c.startDate = date(daysAgo: 10)
        let logOnStart = log(fromPage: 0, toPage: 30, daysAgo: 10)
        XCTAssertEqual(ReadingCalculations.challengeProgress(challenge: c, logs: [logOnStart], books: []), 1)
    }

    // MARK: - booksCount: future-start

    func testBooksCountFutureStartChallengeReturnsZero() {
        // Challenge starts tomorrow; effectiveEnd = today, so end == start → empty date range
        let tomorrow = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: Date()))!
        let futureEnd = cal.date(byAdding: .day, value: 30, to: Date())!
        let c = ReadingChallenge(title: "Future", type: .booksCount, target: 5, endDate: futureEnd)
        c.startDate = tomorrow
        let book = Book(title: "Dune", author: "Herbert", totalPages: 100)
        book.currentPage = 100
        book.dateFinished = date(daysAgo: 0)  // finished today — before challenge starts
        XCTAssertEqual(ReadingCalculations.challengeProgress(challenge: c, logs: [], books: [book]), 0)
    }

    // MARK: - streakDays: future-start

    func testStreakDaysFutureStartChallengeReturnsZero() {
        // Challenge starts tomorrow; no days in window → streak = 0
        let tomorrow = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: Date()))!
        let futureEnd = cal.date(byAdding: .day, value: 30, to: Date())!
        let c = ReadingChallenge(title: "Future", type: .streakDays, target: 15, endDate: futureEnd)
        c.startDate = tomorrow
        let logs = [log(fromPage: 0, toPage: 50, daysAgo: 0)]
        XCTAssertEqual(ReadingCalculations.challengeProgress(challenge: c, logs: logs, books: []), 0)
    }

    // MARK: - streakDays: single log

    func testStreakDaysSingleLogMakesStreakOne() {
        // Exactly one log day within the challenge window → best streak = 1
        let c = challenge(type: .streakDays, startDaysAgo: 10, endDaysFromNow: 10)
        c.startDate = date(daysAgo: 10)
        let logs = [log(fromPage: 0, toPage: 40, daysAgo: 3)]
        XCTAssertEqual(ReadingCalculations.challengeProgress(challenge: c, logs: logs, books: []), 1)
    }
}
