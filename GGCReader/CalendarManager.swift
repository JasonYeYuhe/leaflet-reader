import EventKit
import SwiftUI

struct TaskMetadata {
    let bookID: UUID
    let pages: Int

    private static let prefix = "leaflet:"

    var encoded: String {
        "\(Self.prefix)\(bookID.uuidString):\(pages)"
    }

    static func parse(from notes: String?) -> TaskMetadata? {
        guard let notes, let range = notes.range(of: prefix) else { return nil }
        let payload = notes[range.upperBound...]
        let parts = payload.split(separator: ":")
        guard parts.count == 2,
              let uuid = UUID(uuidString: String(parts[0])),
              let pages = Int(parts[1]) else { return nil }
        return TaskMetadata(bookID: uuid, pages: pages)
    }
}

@MainActor
@Observable
final class CalendarManager {
    private let eventStore = EKEventStore()
    private(set) var hasAccess = false
    private(set) var readingCalendar: EKCalendar?
    private(set) var todayEvents: [EKEvent] = []
    private(set) var upcomingEvents: [EKEvent] = []

    var isSetUp: Bool { hasAccess && readingCalendar != nil }

    // MARK: - Authorization

    func requestAccess() async {
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            hasAccess = granted
            if granted {
                setupCalendar()
                refreshEvents()
            }
        } catch {
            print("[CalendarManager] Failed to request access: \(error)")
            hasAccess = false
        }
    }

    // MARK: - Calendar Setup

    private static let calendarName = String(localized: "æstel", comment: "Calendar name for reading tasks")
    private static let legacyCalendarNames = ["拾叶记", "æstel", "Leaflet"]

    private func setupCalendar() {
        let calendars = eventStore.calendars(for: .event)
        let allKnownNames = Set(Self.legacyCalendarNames + [Self.calendarName])
        if let existing = calendars.first(where: { allKnownNames.contains($0.title) }) {
            readingCalendar = existing
            return
        }

        let newCalendar = EKCalendar(for: .event, eventStore: eventStore)
        newCalendar.title = Self.calendarName
        newCalendar.cgColor = CGColor(red: 0.2, green: 0.78, blue: 0.35, alpha: 1.0)

        // Find a suitable source (prefer iCloud for sync)
        if let iCloud = eventStore.sources.first(where: { $0.sourceType == .calDAV }) {
            newCalendar.source = iCloud
        } else if let local = eventStore.sources.first(where: { $0.sourceType == .local }) {
            newCalendar.source = local
        } else if let defaultSource = eventStore.defaultCalendarForNewEvents?.source {
            newCalendar.source = defaultSource
        }

        do {
            try eventStore.saveCalendar(newCalendar, commit: true)
            readingCalendar = newCalendar
        } catch {
            print("[CalendarManager] Failed to create calendar: \(error)")
            // Use default calendar as fallback
            readingCalendar = eventStore.defaultCalendarForNewEvents
        }
    }

    // MARK: - Fetch Events

    func refreshEvents() {
        guard let calendar = readingCalendar else { return }

        let cal = Calendar.current
        let startOfDay = cal.startOfDay(for: Date())
        guard let endOfDay = cal.date(byAdding: .day, value: 1, to: startOfDay),
              let weekFromNow = cal.date(byAdding: .day, value: 7, to: endOfDay) else { return }

        let todayPredicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: [calendar])
        todayEvents = eventStore.events(matching: todayPredicate)

        let upcomingPredicate = eventStore.predicateForEvents(withStart: endOfDay, end: weekFromNow, calendars: [calendar])
        upcomingEvents = eventStore.events(matching: upcomingPredicate)
    }

    // MARK: - Goal Completion

    func recordGoalCompletion(pages: Int, goal: Int) {
        guard let calendar = readingCalendar else { return }

        // Don't duplicate — check if already recorded today
        let today = Calendar.current.startOfDay(for: Date())
        if todayEvents.contains(where: { ($0.title ?? "").hasPrefix("✅") && Calendar.current.isDate($0.startDate, inSameDayAs: today) }) {
            return
        }

        let event = EKEvent(eventStore: eventStore)
        event.title = "✅ \(String(localized: "Goal Complete!")) \(pages)/\(goal)"
        event.calendar = calendar
        event.startDate = today
        event.endDate = today
        event.isAllDay = true

        do {
            try eventStore.save(event, span: .thisEvent, commit: true)
            refreshEvents()
        } catch {
            print("[CalendarManager] Failed to save goal completion: \(error)")
        }
    }

    // MARK: - Task Management

    func addTask(title: String, date: Date, metadata: TaskMetadata? = nil) {
        guard let calendar = readingCalendar else { return }

        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.calendar = calendar
        event.startDate = Calendar.current.startOfDay(for: date)
        event.endDate = Calendar.current.startOfDay(for: date)
        event.isAllDay = true
        event.notes = metadata?.encoded

        do {
            try eventStore.save(event, span: .thisEvent, commit: true)
            refreshEvents()
        } catch {
            print("[CalendarManager] Failed to save task: \(error)")
        }
    }

    /// Returns metadata if the event has book info attached
    func metadata(for event: EKEvent) -> TaskMetadata? {
        let target: EKEvent
        if let fresh = eventStore.event(withIdentifier: event.eventIdentifier) {
            target = fresh
        } else {
            target = event
        }
        return TaskMetadata.parse(from: target.notes)
    }

    /// Check if event is marked completed
    func isCompleted(_ event: EKEvent) -> Bool {
        (event.title ?? "").hasPrefix("✅")
    }

    func toggleTaskCompletion(_ event: EKEvent) {
        // Try fresh fetch first, fall back to direct event
        let target: EKEvent
        if let fresh = eventStore.event(withIdentifier: event.eventIdentifier) {
            target = fresh
        } else {
            target = event
        }

        let title = target.title ?? ""
        if title.hasPrefix("✅ ") {
            target.title = String(title.dropFirst(2))
        } else {
            target.title = "✅ " + title
        }

        do {
            try eventStore.save(target, span: .thisEvent, commit: true)
        } catch {
            print("[CalendarManager] Failed to toggle task completion: \(error)")
        }

        // Force UI update by re-fetching
        todayEvents = []
        upcomingEvents = []
        refreshEvents()
    }

    func deleteTask(_ event: EKEvent) {
        let target: EKEvent
        if let fresh = eventStore.event(withIdentifier: event.eventIdentifier) {
            target = fresh
        } else {
            target = event
        }

        do {
            try eventStore.remove(target, span: .thisEvent, commit: true)
        } catch {
            print("[CalendarManager] Failed to delete task: \(error)")
        }

        // Force UI update by re-fetching
        todayEvents = []
        upcomingEvents = []
        refreshEvents()
    }
}
