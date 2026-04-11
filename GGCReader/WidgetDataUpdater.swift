import Foundation
import SwiftData
import WidgetKit

@MainActor
enum WidgetDataUpdater {
    static func update(books: [Book], allLogs: [ReadingLog]) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let dailyGoal = UserDefaults.standard.integer(forKey: "dailyPageGoal")
        let goal = dailyGoal > 0 ? dailyGoal : 20

        // Today's pages
        let todayPages = allLogs
            .filter { $0.date >= startOfDay }
            .reduce(0) { $0 + $1.pagesRead }

        // Current book (most recently read, not finished)
        let currentBook = books
            .filter { !$0.isFinished }
            .sorted { ($0.lastReadDate ?? .distantPast) > ($1.lastReadDate ?? .distantPast) }
            .first

        let widgetBook: WidgetBookData? = currentBook.map {
            WidgetBookData(
                title: $0.title,
                author: $0.author,
                currentPage: $0.currentPage,
                totalPages: $0.totalPages,
                colorName: $0.coverColorName,
                progressPercentage: $0.progressPercentage
            )
        }

        // Current streak
        var dailyPages: [Date: Int] = [:]
        for log in allLogs {
            let day = calendar.startOfDay(for: log.date)
            dailyPages[day, default: 0] += log.pagesRead
        }

        var streak = 0
        var date = startOfDay
        if (dailyPages[date] ?? 0) < goal {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: date) else {
                saveAndReload(widgetBook: widgetBook, todayPages: todayPages, goal: goal, streak: 0)
                return
            }
            date = yesterday
        }
        while (dailyPages[date] ?? 0) >= goal {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: date) else { break }
            date = prev
        }

        saveAndReload(widgetBook: widgetBook, todayPages: todayPages, goal: goal, streak: streak)
    }

    private static func saveAndReload(widgetBook: WidgetBookData?, todayPages: Int, goal: Int, streak: Int) {
        let data = WidgetData(
            currentBook: widgetBook,
            todayPages: todayPages,
            dailyGoal: goal,
            currentStreak: streak,
            lastUpdated: Date()
        )
        WidgetData.save(data)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
