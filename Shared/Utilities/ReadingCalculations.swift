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

    // MARK: - Challenge Progress

    static func challengeProgress(
        challenge: ReadingChallenge,
        logs: [ReadingLog],
        books: [Book],
        today: Date = Date()
    ) -> Int {
        let cal = Calendar.current
        let start = cal.startOfDay(for: challenge.startDate)
        let effectiveEnd = min(challenge.endDate, today)
        let end = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: effectiveEnd)) ?? effectiveEnd

        switch challenge.challengeType {
        case .booksCount:
            return books.filter {
                $0.isFinished &&
                ($0.dateFinished ?? $0.lastReadDate ?? .distantFuture) >= start &&
                ($0.dateFinished ?? $0.lastReadDate ?? .distantFuture) < end
            }.count

        case .pagesCount:
            return logs.filter { $0.date >= start && $0.date < end }
                .reduce(0) { $0 + $1.pagesRead }

        case .streakDays:
            var daySet = Set<Date>()
            for log in logs where log.date >= start && log.date < end {
                daySet.insert(cal.startOfDay(for: log.date))
            }
            var best = 0
            var current = 0
            let totalDays = max((cal.dateComponents([.day], from: start, to: end).day ?? 0) + 1, 1)
            for offset in 0..<totalDays {
                guard let date = cal.date(byAdding: .day, value: offset, to: start) else { continue }
                if daySet.contains(date) {
                    current += 1
                    best = max(best, current)
                } else {
                    current = 0
                }
            }
            return best

        case .readingDays:
            var daySet = Set<Date>()
            for log in logs where log.date >= start && log.date < end {
                daySet.insert(cal.startOfDay(for: log.date))
            }
            return daySet.count
        }
    }
}
