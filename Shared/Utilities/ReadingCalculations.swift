import Foundation

enum ReadingCalculations {
    static func percentage(currentPage: Int, totalPages: Int) -> Double {
        guard totalPages > 0 else { return 0 }
        return min(Double(currentPage) / Double(totalPages), 1.0)
    }

    static func currentChapter(page: Int, chapters: [Chapter]) -> Chapter? {
        chapters
            .sorted { $0.startPage < $1.startPage }
            .last { $0.startPage <= page }
    }

    static func pagesRemaining(currentPage: Int, totalPages: Int) -> Int {
        max(totalPages - currentPage, 0)
    }

    static func readingSpeed(logs: [ReadingLog], days: Int = 7) -> Double {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let recentLogs = logs.filter { $0.date >= cutoff }
        let totalPages = recentLogs.reduce(0) { $0 + $1.pagesRead }
        return days > 0 ? Double(totalPages) / Double(days) : 0
    }
}
