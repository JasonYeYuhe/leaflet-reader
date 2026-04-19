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
        XCTAssertEqual(badges.count, 29)
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

    // MARK: - Pages badges (additional thresholds)

    func testBookwormUnlockedAt500() {
        let badges = buildBadges(from: makeStats(totalPages: 500))
        let b = badges.first { $0.id == "bookworm" }!
        XCTAssertTrue(b.isUnlocked)
    }

    func testPageTurnerUnlockedAt1000() {
        let badges = buildBadges(from: makeStats(totalPages: 1000))
        let b = badges.first { $0.id == "thousand" }!
        XCTAssertTrue(b.isUnlocked)
    }

    func testSageUnlockedAt5000() {
        let badges = buildBadges(from: makeStats(totalPages: 5000))
        let b = badges.first { $0.id == "five_thousand" }!
        XCTAssertTrue(b.isUnlocked)
    }

    // MARK: - Streak badges (additional thresholds)

    func testStreak30UnlockedAt30() {
        let badges = buildBadges(from: makeStats(bestStreak: 30))
        let b = badges.first { $0.id == "streak30" }!
        XCTAssertTrue(b.isUnlocked)
    }

    func testStreak100UnlockedAt100() {
        let badges = buildBadges(from: makeStats(bestStreak: 100))
        let b = badges.first { $0.id == "streak100" }!
        XCTAssertTrue(b.isUnlocked)
    }

    // MARK: - Finished books (additional thresholds)

    func testHatTrickUnlockedAt3() {
        let badges = buildBadges(from: makeStats(finishedBooks: 3))
        let b = badges.first { $0.id == "three_books" }!
        XCTAssertTrue(b.isUnlocked)
    }

    func testBibliophileUnlockedAt10() {
        let badges = buildBadges(from: makeStats(finishedBooks: 10))
        let b = badges.first { $0.id == "ten_books" }!
        XCTAssertTrue(b.isUnlocked)
    }

    func testScholarUnlockedAt25() {
        let badges = buildBadges(from: makeStats(finishedBooks: 25))
        let b = badges.first { $0.id == "twentyfive_books" }!
        XCTAssertTrue(b.isUnlocked)
    }

    // MARK: - Reading days

    func testDedicatedUnlockedAt7Days() {
        let badges = buildBadges(from: makeStats(daysRead: 7))
        let b = badges.first { $0.id == "week_reader" }!
        XCTAssertTrue(b.isUnlocked)
    }

    func testCommittedUnlockedAt30Days() {
        let badges = buildBadges(from: makeStats(daysRead: 30))
        let b = badges.first { $0.id == "month_reader" }!
        XCTAssertTrue(b.isUnlocked)
    }

    func testCenturionDaysUnlockedAt100() {
        let badges = buildBadges(from: makeStats(daysRead: 100))
        let b = badges.first { $0.id == "hundred_days" }!
        XCTAssertTrue(b.isUnlocked)
    }

    // MARK: - Daily records

    func testSpeedReaderUnlockedAt50() {
        let badges = buildBadges(from: makeStats(bestSingleDay: 50))
        let b = badges.first { $0.id == "fifty_day" }!
        XCTAssertTrue(b.isUnlocked)
    }

    func testMarathonUnlockedAt100() {
        let badges = buildBadges(from: makeStats(bestSingleDay: 100))
        let b = badges.first { $0.id == "hundred_day" }!
        XCTAssertTrue(b.isUnlocked)
    }

    // MARK: - Goal badges

    func testGoalGetterUnlockedAt7() {
        let badges = buildBadges(from: makeStats(goalMetDays: 7))
        let b = badges.first { $0.id == "goal_7" }!
        XCTAssertTrue(b.isUnlocked)
    }

    func testDisciplinedUnlockedAt30() {
        let badges = buildBadges(from: makeStats(goalMetDays: 30))
        let b = badges.first { $0.id == "goal_30" }!
        XCTAssertTrue(b.isUnlocked)
    }

    // MARK: - Collection badges

    func testCollectorUnlockedAt5() {
        let badges = buildBadges(from: makeStats(totalBooks: 5))
        let b = badges.first { $0.id == "five_books_shelf" }!
        XCTAssertTrue(b.isUnlocked)
    }

    func testHomeLibraryUnlockedAt20() {
        let badges = buildBadges(from: makeStats(totalBooks: 20))
        let b = badges.first { $0.id == "twenty_books_shelf" }!
        XCTAssertTrue(b.isUnlocked)
    }

    // MARK: - Night owl

    func testNightOwlUnlockedAt3Days() {
        let badges = buildBadges(from: makeStats(nightOwlDays: 3))
        let b = badges.first { $0.id == "night_owl" }!
        XCTAssertTrue(b.isUnlocked)
    }

    // MARK: - All locked at zero stats

    func testAllLockedAtZeroStats() {
        let badges = buildBadges(from: makeStats())
        XCTAssertTrue(badges.allSatisfy { !$0.isUnlocked })
    }

    // MARK: - Badge struct integrity

    func testAllBadgeIDsAreUnique() {
        let badges = buildBadges(from: makeStats())
        let ids = badges.map { $0.id }
        XCTAssertEqual(ids.count, Set(ids).count)
    }

    func testAllBadgeIconsAreNonEmpty() {
        let badges = buildBadges(from: makeStats())
        XCTAssertTrue(badges.allSatisfy { !$0.icon.isEmpty })
    }

    // MARK: - Lower boundary (threshold - 1 remains locked)

    func testStreak7UnlockedAtExactThreshold() {
        let badges = buildBadges(from: makeStats(bestStreak: 7))
        XCTAssertTrue(badges.first { $0.id == "streak7" }?.isUnlocked == true)
    }

    func testCenturionLockedAt99Pages() {
        let badges = buildBadges(from: makeStats(totalPages: 99))
        XCTAssertFalse(badges.first { $0.id == "centurion" }?.isUnlocked == true)
    }

    func testStreak365LockedAt364Days() {
        let badges = buildBadges(from: makeStats(bestStreak: 364))
        XCTAssertFalse(badges.first { $0.id == "streak365" }?.isUnlocked == true)
    }

    func testHatTrickLockedAt2Books() {
        let badges = buildBadges(from: makeStats(finishedBooks: 2))
        XCTAssertFalse(badges.first { $0.id == "three_books" }?.isUnlocked == true)
    }

    func testSpeedReaderLockedAt49Pages() {
        let badges = buildBadges(from: makeStats(bestSingleDay: 49))
        XCTAssertFalse(badges.first { $0.id == "fifty_day" }?.isUnlocked == true)
    }

    func testWeekendWarriorLockedAt9Days() {
        let badges = buildBadges(from: makeStats(weekendDaysRead: 9))
        XCTAssertFalse(badges.first { $0.id == "weekend_warrior" }?.isUnlocked == true)
    }

    func testGoalGetterLockedAt6Days() {
        let badges = buildBadges(from: makeStats(goalMetDays: 6))
        XCTAssertFalse(badges.first { $0.id == "goal_7" }?.isUnlocked == true)
    }

    func testCollectorLockedAt4Books() {
        let badges = buildBadges(from: makeStats(totalBooks: 4))
        XCTAssertFalse(badges.first { $0.id == "five_books_shelf" }?.isUnlocked == true)
    }

    func testExplorerLockedAt4Authors() {
        let badges = buildBadges(from: makeStats(distinctAuthors: 4))
        XCTAssertFalse(badges.first { $0.id == "diverse_reader" }?.isUnlocked == true)
    }

    func testEarlyBirdLockedAt2Days() {
        let badges = buildBadges(from: makeStats(earlyBirdDays: 2))
        XCTAssertFalse(badges.first { $0.id == "early_bird" }?.isUnlocked == true)
    }
}
