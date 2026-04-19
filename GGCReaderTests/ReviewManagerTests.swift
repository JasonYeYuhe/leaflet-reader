import XCTest
@testable import GGCReader

@MainActor
final class ReviewManagerTests: XCTestCase {

    private let finishedBooksKey = "reviewManager.finishedBooksCount"
    private let highestStreakHandledKey = "reviewManager.highestStreakHandled"
    private let lastPromptedVersionKey = "reviewManager.lastPromptedVersion"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: finishedBooksKey)
        UserDefaults.standard.removeObject(forKey: highestStreakHandledKey)
        UserDefaults.standard.removeObject(forKey: lastPromptedVersionKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: finishedBooksKey)
        UserDefaults.standard.removeObject(forKey: highestStreakHandledKey)
        UserDefaults.standard.removeObject(forKey: lastPromptedVersionKey)
        super.tearDown()
    }

    // MARK: - recordBookFinished

    func testRecordBookFinishedIncrementsCount() {
        ReviewManager.recordBookFinished()
        XCTAssertEqual(UserDefaults.standard.integer(forKey: finishedBooksKey), 1)
    }

    func testRecordBookFinishedAccumulatesCorrectly() {
        ReviewManager.recordBookFinished()
        ReviewManager.recordBookFinished()
        XCTAssertEqual(UserDefaults.standard.integer(forKey: finishedBooksKey), 2)
    }

    func testRecordBookFinishedThirdBookReachesThreshold() {
        ReviewManager.recordBookFinished()
        ReviewManager.recordBookFinished()
        ReviewManager.recordBookFinished()
        XCTAssertEqual(UserDefaults.standard.integer(forKey: finishedBooksKey), 3)
    }

    func testRecordBookFinishedContinuesPastThreshold() {
        for _ in 1...5 {
            ReviewManager.recordBookFinished()
        }
        XCTAssertEqual(UserDefaults.standard.integer(forKey: finishedBooksKey), 5)
    }

    // MARK: - recordStreakIfNewMilestone

    func testStreakZeroDoesNothing() {
        ReviewManager.recordStreakIfNewMilestone(0)
        XCTAssertEqual(UserDefaults.standard.integer(forKey: highestStreakHandledKey), 0)
    }

    func testStreakBelowFirstMilestoneDoesNothing() {
        ReviewManager.recordStreakIfNewMilestone(6)
        XCTAssertEqual(UserDefaults.standard.integer(forKey: highestStreakHandledKey), 0)
    }

    func testStreakExactlyAtFirstMilestoneSetsHighestHandled() {
        ReviewManager.recordStreakIfNewMilestone(7)
        XCTAssertEqual(UserDefaults.standard.integer(forKey: highestStreakHandledKey), 7)
    }

    func testStreakAlreadyHandledSameValueIsNoOp() {
        ReviewManager.recordStreakIfNewMilestone(7)
        ReviewManager.recordStreakIfNewMilestone(7)
        XCTAssertEqual(UserDefaults.standard.integer(forKey: highestStreakHandledKey), 7)
    }

    func testStreakAdvancesFrom7To30() {
        ReviewManager.recordStreakIfNewMilestone(7)
        ReviewManager.recordStreakIfNewMilestone(30)
        XCTAssertEqual(UserDefaults.standard.integer(forKey: highestStreakHandledKey), 30)
    }

    func testStreakAt100WithHighestHandledAt30() {
        // Pre-seed: 30 already handled; next call with streak≥100 picks 100
        UserDefaults.standard.set(30, forKey: highestStreakHandledKey)
        ReviewManager.recordStreakIfNewMilestone(100)
        XCTAssertEqual(UserDefaults.standard.integer(forKey: highestStreakHandledKey), 100)
    }

    func testStreakAt365WithHighestHandledAt100() {
        // Pre-seed: 100 already handled; next call with streak≥365 picks 365
        UserDefaults.standard.set(100, forKey: highestStreakHandledKey)
        ReviewManager.recordStreakIfNewMilestone(365)
        XCTAssertEqual(UserDefaults.standard.integer(forKey: highestStreakHandledKey), 365)
    }

    func testStreakBeyond365DoesNotChangeHighestHandled() {
        // Pre-seed: 365 already handled; no milestone > 365 exists
        UserDefaults.standard.set(365, forKey: highestStreakHandledKey)
        ReviewManager.recordStreakIfNewMilestone(500)
        XCTAssertEqual(UserDefaults.standard.integer(forKey: highestStreakHandledKey), 365)
    }

    func testStreakJumpsToFirstMatchingMilestoneOnly() {
        // first(where:) on [7,30,100,365] with streak=100, highestHandled=0 → picks 7
        ReviewManager.recordStreakIfNewMilestone(100)
        XCTAssertEqual(UserDefaults.standard.integer(forKey: highestStreakHandledKey), 7)
    }
}
