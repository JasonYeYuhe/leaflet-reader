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

    // MARK: - currentChapter

    func testCurrentChapterEmptyReturnsNil() {
        XCTAssertNil(ReadingCalculations.currentChapter(page: 50, chapters: []))
    }

    func testCurrentChapterSingleChapterAtStart() {
        let ch = Chapter(name: "Ch 1", startPage: 1, endPage: 100)
        let result = ReadingCalculations.currentChapter(page: 1, chapters: [ch])
        XCTAssertEqual(result?.name, "Ch 1")
    }

    func testCurrentChapterPageBeforeFirstReturnsNil() {
        let ch = Chapter(name: "Ch 1", startPage: 10, endPage: 100)
        XCTAssertNil(ReadingCalculations.currentChapter(page: 5, chapters: [ch]))
    }

    func testCurrentChapterMultipleChaptersSelectsCorrect() {
        let ch1 = Chapter(name: "Part I", startPage: 1, endPage: 100)
        let ch2 = Chapter(name: "Part II", startPage: 101, endPage: 200)
        let result = ReadingCalculations.currentChapter(page: 150, chapters: [ch1, ch2])
        XCTAssertEqual(result?.name, "Part II")
    }

    func testCurrentChapterUnsortedInputNormalized() {
        let ch1 = Chapter(name: "Part I", startPage: 1, endPage: 100)
        let ch2 = Chapter(name: "Part II", startPage: 101, endPage: 200)
        let result = ReadingCalculations.currentChapter(page: 50, chapters: [ch2, ch1])
        XCTAssertEqual(result?.name, "Part I")
    }

    // MARK: - readingSpeed

    func testReadingSpeedEmptyLogs() {
        let speed = ReadingCalculations.readingSpeed(logs: [], days: 7)
        XCTAssertEqual(speed, 0.0)
    }

    func testReadingSpeedZeroDays() {
        let log = ReadingLog(fromPage: 0, toPage: 50)
        let speed = ReadingCalculations.readingSpeed(logs: [log], days: 0)
        XCTAssertEqual(speed, 0.0)
    }

    func testReadingSpeedSingleLog() {
        let log = ReadingLog(fromPage: 0, toPage: 70)
        let speed = ReadingCalculations.readingSpeed(logs: [log], days: 7)
        XCTAssertEqual(speed, 70.0 / 7.0, accuracy: 0.001)
    }

    func testReadingSpeedMultipleLogs() {
        let log1 = ReadingLog(fromPage: 0, toPage: 30)
        let log2 = ReadingLog(fromPage: 30, toPage: 80)
        let speed = ReadingCalculations.readingSpeed(logs: [log1, log2], days: 7)
        XCTAssertEqual(speed, 80.0 / 7.0, accuracy: 0.001)
    }

    func testReadingSpeedFiltersOldLogs() {
        let recent = ReadingLog(fromPage: 0, toPage: 50)
        let old = ReadingLog(fromPage: 0, toPage: 100)
        old.date = .distantPast
        let speed = ReadingCalculations.readingSpeed(logs: [recent, old], days: 7)
        XCTAssertEqual(speed, 50.0 / 7.0, accuracy: 0.001)
    }

    func testReadingSpeedOneDayWindow() {
        let log = ReadingLog(fromPage: 0, toPage: 60)
        let speed = ReadingCalculations.readingSpeed(logs: [log], days: 1)
        XCTAssertEqual(speed, 60.0, accuracy: 0.001)
    }

    func testReadingSpeedNegativeDaysReturnsZero() {
        let log = ReadingLog(fromPage: 0, toPage: 100)
        let speed = ReadingCalculations.readingSpeed(logs: [log], days: -5)
        XCTAssertEqual(speed, 0.0)
    }

    func testReadingSpeedLogJustOutsideWindowExcluded() {
        // A log 8 days ago should fall outside the 7-day window and be excluded
        let old = ReadingLog(fromPage: 0, toPage: 80)
        old.date = Date().addingTimeInterval(-8 * 24 * 3600)
        let speed = ReadingCalculations.readingSpeed(logs: [old], days: 7)
        XCTAssertEqual(speed, 0.0)
    }

    func testReadingSpeedThirtyDayWindow() {
        let log = ReadingLog(fromPage: 0, toPage: 90)
        let speed = ReadingCalculations.readingSpeed(logs: [log], days: 30)
        XCTAssertEqual(speed, 90.0 / 30.0, accuracy: 0.001)
    }

    func testReadingSpeedCustomWindowMultipleLogs() {
        let log1 = ReadingLog(fromPage: 0, toPage: 40)
        let log2 = ReadingLog(fromPage: 40, toPage: 70)
        // Both logs created just now, well within a 14-day window
        let speed = ReadingCalculations.readingSpeed(logs: [log1, log2], days: 14)
        XCTAssertEqual(speed, 70.0 / 14.0, accuracy: 0.001)
    }

    // MARK: - dailyPages

    func testDailyPagesEmptyLogsReturnsEmptyMap() {
        let map = ReadingCalculations.dailyPages(from: [])
        XCTAssertTrue(map.isEmpty)
    }

    func testDailyPagesAggregatesLogsOnSameDay() {
        let log1 = ReadingLog(fromPage: 0, toPage: 30)
        let log2 = ReadingLog(fromPage: 30, toPage: 50)
        let map = ReadingCalculations.dailyPages(from: [log1, log2])
        let today = Calendar.current.startOfDay(for: Date())
        XCTAssertEqual(map[today], 50)
    }

    func testDailyPagesDifferentDaysAreSeparate() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!

        var log1 = ReadingLog(fromPage: 0, toPage: 20)
        log1.date = today
        var log2 = ReadingLog(fromPage: 20, toPage: 45)
        log2.date = yesterday

        let map = ReadingCalculations.dailyPages(from: [log1, log2])
        XCTAssertEqual(map[today], 20)
        XCTAssertEqual(map[yesterday], 25)
    }

    // MARK: - currentGoalStreak

    func testCurrentGoalStreakNoLogsReturnsZero() {
        XCTAssertEqual(ReadingCalculations.currentGoalStreak(logs: [], goal: 20), 0)
    }

    func testCurrentGoalStreakTodayMeetsGoal() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var log = ReadingLog(fromPage: 0, toPage: 25)
        log.date = today
        XCTAssertEqual(ReadingCalculations.currentGoalStreak(logs: [log], goal: 20), 1)
    }

    func testCurrentGoalStreakYesterdayMeetsGoalTodayDoesNot() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
        var log = ReadingLog(fromPage: 0, toPage: 25)
        log.date = yesterday
        // today has 0 pages (<goal), so we look at yesterday which has 25 >= 20
        XCTAssertEqual(ReadingCalculations.currentGoalStreak(logs: [log], goal: 20), 1)
    }

    func testCurrentGoalStreakTwoDaysConsecutive() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
        var log1 = ReadingLog(fromPage: 0, toPage: 25)
        log1.date = today
        var log2 = ReadingLog(fromPage: 25, toPage: 50)
        log2.date = yesterday
        XCTAssertEqual(ReadingCalculations.currentGoalStreak(logs: [log1, log2], goal: 20), 2)
    }

    func testCurrentGoalStreakBreaksTwoBackWithGap() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let twoDaysAgo = cal.date(byAdding: .day, value: -2, to: today)!
        // today: 0 pages, yesterday: 0 pages, two days ago: 30 pages
        // streak should be 0 because neither today nor yesterday meets goal
        var log = ReadingLog(fromPage: 0, toPage: 30)
        log.date = twoDaysAgo
        XCTAssertEqual(ReadingCalculations.currentGoalStreak(logs: [log], goal: 20), 0)
    }

    // MARK: - bestGoalStreak

    func testBestGoalStreakNoLogsReturnsZero() {
        XCTAssertEqual(ReadingCalculations.bestGoalStreak(logs: [], goal: 20), 0)
    }

    func testBestGoalStreakSingleDayMeetsGoal() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var log = ReadingLog(fromPage: 0, toPage: 30)
        log.date = today
        XCTAssertEqual(ReadingCalculations.bestGoalStreak(logs: [log], goal: 20), 1)
    }

    func testBestGoalStreakThreeConsecutiveDays() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let days = (0..<3).compactMap { cal.date(byAdding: .day, value: -$0, to: today) }
        let logs: [ReadingLog] = days.map { day in
            var log = ReadingLog(fromPage: 0, toPage: 25)
            log.date = day
            return log
        }
        XCTAssertEqual(ReadingCalculations.bestGoalStreak(logs: logs, goal: 20), 3)
    }

    func testBestGoalStreakWithGapCountsBestRun() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        // days 0,1,2 meet goal; day 3 does not; days 4,5 meet goal
        // best streak should be 3
        let meetingOffsets = [0, 1, 2, 4, 5]
        let logs: [ReadingLog] = meetingOffsets.compactMap { offset in
            guard let day = cal.date(byAdding: .day, value: -offset, to: today) else { return nil }
            var log = ReadingLog(fromPage: 0, toPage: 25)
            log.date = day
            return log
        }
        XCTAssertEqual(ReadingCalculations.bestGoalStreak(logs: logs, goal: 20), 3)
    }

    func testBestGoalStreakFutureOnlyLogsReturnsZero() {
        // all logs in future → totalDays negative → must return 0, not crash
        let cal = Calendar.current
        let tomorrow = cal.date(byAdding: .day, value: 1, to: Date())!
        var log = ReadingLog(fromPage: 0, toPage: 50)
        log.date = tomorrow
        XCTAssertEqual(ReadingCalculations.bestGoalStreak(logs: [log], goal: 1), 0)
    }

    func testBestGoalStreakPastAndFutureLogsCountsOnlyPast() {
        // one log today (meets goal) + one log tomorrow → streak = 1
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let tomorrow = cal.date(byAdding: .day, value: 1, to: today)!
        var logToday = ReadingLog(fromPage: 0, toPage: 30)
        logToday.date = today
        var logTomorrow = ReadingLog(fromPage: 0, toPage: 30)
        logTomorrow.date = tomorrow
        XCTAssertEqual(ReadingCalculations.bestGoalStreak(logs: [logToday, logTomorrow], goal: 20), 1)
    }

    func testBestGoalStreakFutureMultipleLogsReturnsZero() {
        // multiple future-dated logs must not crash
        let cal = Calendar.current
        let logs: [ReadingLog] = (1...5).map { offset in
            let day = cal.date(byAdding: .day, value: offset, to: Date())!
            var log = ReadingLog(fromPage: 0, toPage: 20)
            log.date = day
            return log
        }
        XCTAssertEqual(ReadingCalculations.bestGoalStreak(logs: logs, goal: 1), 0)
    }
}
