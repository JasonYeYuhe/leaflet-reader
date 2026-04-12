import UserNotifications
import SwiftUI

@MainActor
@Observable
final class ReminderManager {
    private(set) var isAuthorized = false
    var reminderEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "reminderEnabled") }
        set {
            UserDefaults.standard.set(newValue, forKey: "reminderEnabled")
            if newValue {
                scheduleReminder()
            } else {
                cancelReminder()
            }
        }
    }

    var reminderHour: Int {
        get {
            let h = UserDefaults.standard.integer(forKey: "reminderHour")
            return h == 0 && !UserDefaults.standard.bool(forKey: "reminderHourSet") ? 21 : h
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "reminderHour")
            UserDefaults.standard.set(true, forKey: "reminderHourSet")
            if reminderEnabled { scheduleReminder() }
        }
    }

    var reminderMinute: Int {
        get { UserDefaults.standard.integer(forKey: "reminderMinute") }
        set {
            UserDefaults.standard.set(newValue, forKey: "reminderMinute")
            if reminderEnabled { scheduleReminder() }
        }
    }

    private static let reminderID = "com.leaflet.dailyReadingReminder"

    func requestAccess() async {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
        } catch {
            isAuthorized = false
        }
    }

    func checkAuthStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    func scheduleReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.reminderID])

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Time to Read!")
        content.body = String(localized: "Don't forget to reach your daily reading goal.")
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = reminderHour
        dateComponents.minute = reminderMinute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: Self.reminderID, content: content, trigger: trigger)

        center.add(request) { _ in }
    }

    func cancelReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Self.reminderID])
    }

    // MARK: - Weekly Summary (Pro)

    private static let weeklySummaryID = "com.aestel.weeklySummary"

    var weeklySummaryEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "weeklySummaryEnabled") }
        set {
            UserDefaults.standard.set(newValue, forKey: "weeklySummaryEnabled")
            if newValue {
                scheduleWeeklySummary()
            } else {
                cancelWeeklySummary()
            }
        }
    }

    func scheduleWeeklySummary() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.weeklySummaryID])

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Weekly Reading Summary")
        content.body = String(localized: "Check out how much you read this week!")
        content.sound = .default

        // Every Sunday at 10 AM
        var dateComponents = DateComponents()
        dateComponents.weekday = 1 // Sunday
        dateComponents.hour = 10
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: Self.weeklySummaryID, content: content, trigger: trigger)

        center.add(request) { _ in }
    }

    func cancelWeeklySummary() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Self.weeklySummaryID])
    }
}
