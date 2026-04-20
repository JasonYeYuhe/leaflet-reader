import XCTest
@testable import GGCReader

@MainActor
final class ReminderManagerTests: XCTestCase {

    private let enabledKey = "reminderEnabled"
    private let hourKey = "reminderHour"
    private let hourSetKey = "reminderHourSet"
    private let minuteKey = "reminderMinute"
    private let weeklySummaryKey = "weeklySummaryEnabled"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: enabledKey)
        UserDefaults.standard.removeObject(forKey: hourKey)
        UserDefaults.standard.removeObject(forKey: hourSetKey)
        UserDefaults.standard.removeObject(forKey: minuteKey)
        UserDefaults.standard.removeObject(forKey: weeklySummaryKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: enabledKey)
        UserDefaults.standard.removeObject(forKey: hourKey)
        UserDefaults.standard.removeObject(forKey: hourSetKey)
        UserDefaults.standard.removeObject(forKey: minuteKey)
        UserDefaults.standard.removeObject(forKey: weeklySummaryKey)
        super.tearDown()
    }

    // MARK: - reminderEnabled

    func testReminderEnabledDefaultsFalse() {
        let m = ReminderManager()
        XCTAssertFalse(m.reminderEnabled)
    }

    func testReminderEnabledStoresTrueViaUserDefaults() {
        // Write directly to bypass scheduleReminder side effect
        UserDefaults.standard.set(true, forKey: enabledKey)
        let m = ReminderManager()
        XCTAssertTrue(m.reminderEnabled)
    }

    func testReminderEnabledSetterToFalseIsReflected() {
        let m = ReminderManager()
        // cancelReminder() is safe: removePendingNotificationRequests is a no-op when none exist
        m.reminderEnabled = false
        XCTAssertFalse(m.reminderEnabled)
    }

    // MARK: - reminderHour

    func testReminderHourDefaultsTo21WhenNotSet() {
        // Neither reminderHour nor reminderHourSet written → guard returns 21
        let m = ReminderManager()
        XCTAssertEqual(m.reminderHour, 21)
    }

    func testReminderHourReturnsZeroWhenExplicitlySetToZero() {
        // Setter writes reminderHourSet=true so 0 is not mistaken for "unset"
        let m = ReminderManager()
        m.reminderHour = 0
        XCTAssertEqual(m.reminderHour, 0)
    }

    func testReminderHourStoresCustomValue() {
        let m = ReminderManager()
        m.reminderHour = 8
        XCTAssertEqual(m.reminderHour, 8)
    }

    func testReminderHourSetterMarksFlagInUserDefaults() {
        let m = ReminderManager()
        m.reminderHour = 9
        XCTAssertTrue(UserDefaults.standard.bool(forKey: hourSetKey))
    }

    // MARK: - reminderMinute

    func testReminderMinuteDefaultsToZero() {
        let m = ReminderManager()
        XCTAssertEqual(m.reminderMinute, 0)
    }

    func testReminderMinuteStoresValue() {
        let m = ReminderManager()
        m.reminderMinute = 30
        XCTAssertEqual(m.reminderMinute, 30)
    }

    // MARK: - weeklySummaryEnabled

    func testWeeklySummaryEnabledDefaultsFalse() {
        let m = ReminderManager()
        XCTAssertFalse(m.weeklySummaryEnabled)
    }
}
