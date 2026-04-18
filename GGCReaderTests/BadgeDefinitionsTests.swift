import XCTest
@testable import GGCReader

final class BadgeDefinitionsTests: XCTestCase {

    private func makeStats(
        totalPages: Int = 0,
        totalBooks: Int = 0,
        finishedBooks: Int = 0,
        daysRead: Int = 0,
        bestSingleDay: Int = 0,
        weekendDaysRead: Int = 0,
        earlyBirdDays: Int = 0,
        nightOwlDays: Int = 0,
        distinctAuthors: Int = 0,
        goalMetDays: Int = 0,
        bestStreak: Int = 0
    ) -> BadgeStats {
        BadgeStats(
            totalPages: totalPages,
            totalBooks: totalBooks,
            finishedBooks: finishedBooks,
            daysRead: daysRead,
            bestSingleDay: bestSingleDay,
            weekendDaysRead: weekendDaysRead,
            earlyBirdDays: earlyBirdDays,
            nightOwlDays: nightOwlDays,
            distinctAuthors: distinctAuthors,
            goalMetDays: goalMetDays,
            bestStreak: bestStreak
        )
    }

    // MARK: - Badge count

    func testBadgeCount() {
        let badges = buildBadges(from: makeStats())
        XCTAssertEqual(badges.count, 28)
    }

    // MARK: - Pages badges

    func testFirstPageLockedAtZero() {
        let badges = buildBadges(from: makeStats(totalPages: 0))
        let b = badges.first { $0.id == "first_page" }!
        XCTAssertFalse(b.isUnlocked)
    }

    func testFirstPageUnlockedAtOne() {
        let badges = buildBadges(from: makeStats(totalPages: 1))
        let b = badges.first { $0.id == "first_page" }!
        XCTAssertTrue(b.isUnlocked)
    }

    func testCenturionUnlockedAt100() {
        let badges = buildBadges(from: makeStats(totalPages: 100))
        let b = badges.first { $0.id == "centurion" }!
        XCTAssertTrue(b.isUnlocked)
    }

    func testLegendUnlockedAt10000() {
        let badges = buildBadges(from: makeStats(totalPages: 10000))
        let b = badges.first { $0.id == "ten_thousand" }!
        XCTAssertTrue(b.isUnlocked)
    }

    // MARK: - Streak badges

    func testStreak3UnlockedAt3() {
        let badges = buildBadges(from: makeStats(bestStreak: 3))
        let b = badges.first { $0.id == "streak3" }!
        XCTAssertTrue(b.isUnlocked)
    }

    func testStreak7LockedAt6() {
        let badges = buildBadges(from: makeStats(bestStreak: 6))
        let b = badges.first { $0.id == "streak7" }!
        XCTAssertFalse(b.isUnlocked)
    }

    func testStreak365UnlockedAt365() {
        let badges = buildBadges(from: makeStats(bestStreak: 365))
        let b = badges.first { $0.id == "streak365" }!
        XCTAssertTrue(b.isUnlocked)
    }

    // MARK: - Finished books badges

    func testFirstBookUnlockedAt1() {
        let badges = buildBadges(from: makeStats(finishedBooks: 1))
        let b = badges.first { $0.id == "first_book" }!
        XCTAssertTrue(b.isUnlocked)
    }

    func testWizardUnlockedAt50() {
        let badges = buildBadges(from: makeStats(finishedBooks: 50))
        let b = badges.first { $0.id == "fifty_books" }!
        XCTAssertTrue(b.isUnlocked)
    }

    // MARK: - Special badges

    func testEarlyBirdUnlockedAt3Days() {
        let badges = buildBadges(from: makeStats(earlyBirdDays: 3))
        let b = badges.first { $0.id == "early_bird" }!
        XCTAssertTrue(b.isUnlocked)
    }

    func testNightOwlLockedAt2Days() {
        let badges = buildBadges(from: makeStats(nightOwlDays: 2))
        let b = badges.first { $0.id == "night_owl" }!
        XCTAssertFalse(b.isUnlocked)
    }

    func testExplorerUnlockedAt5Authors() {
        let badges = buildBadges(from: makeStats(distinctAuthors: 5))
        let b = badges.first { $0.id == "diverse_reader" }!
        XCTAssertTrue(b.isUnlocked)
    }

    func testWeekendWarriorUnlockedAt10() {
        let badges = buildBadges(from: makeStats(weekendDaysRead: 10))
        let b = badges.first { $0.id == "weekend_warrior" }!
        XCTAssertTrue(b.isUnlocked)
    }

    // MARK: - All locked at zero stats

    func testAllLockedAtZeroStats() {
        let badges = buildBadges(from: makeStats())
        XCTAssertTrue(badges.allSatisfy { !$0.isUnlocked })
    }
}
