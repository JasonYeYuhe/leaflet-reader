import SwiftUI
import SwiftData

struct GoalsView: View {
    @Query(sort: \ReadingLog.date, order: .reverse) private var allLogs: [ReadingLog]
    @Query(sort: \Book.lastReadDate, order: .reverse) private var books: [Book]
    @AppStorage("dailyPageGoal") private var dailyPageGoal: Int = 20
    @State private var calendarManager = CalendarManager()
    @State private var reminderManager = ReminderManager()
    @State private var showCelebration = false
    @State private var previousProgress: Double = 0

    private let calendar = Calendar.current

    // MARK: - Computed Data

    private var dailyPages: [Date: Int] {
        var map: [Date: Int] = [:]
        for log in allLogs {
            let day = calendar.startOfDay(for: log.date)
            map[day, default: 0] += log.pagesRead
        }
        return map
    }

    private var todayPages: Int {
        dailyPages[calendar.startOfDay(for: Date())] ?? 0
    }

    private var todayProgress: Double {
        guard dailyPageGoal > 0 else { return 0 }
        return min(Double(todayPages) / Double(dailyPageGoal), 1.0)
    }

    private var currentStreak: Int {
        let pages = dailyPages
        var streak = 0
        var date = calendar.startOfDay(for: Date())

        if (pages[date] ?? 0) < dailyPageGoal {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: date) else { return 0 }
            date = yesterday
        }

        while (pages[date] ?? 0) >= dailyPageGoal {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: date) else { break }
            date = prev
        }

        return streak
    }

    private var bestStreak: Int {
        guard let earliest = allLogs.min(by: { $0.date < $1.date })?.date else { return 0 }
        let pages = dailyPages
        let start = calendar.startOfDay(for: earliest)
        let today = calendar.startOfDay(for: Date())
        guard let totalDays = calendar.dateComponents([.day], from: start, to: today).day else { return 0 }

        var best = 0
        var current = 0
        for offset in 0...totalDays {
            guard let date = calendar.date(byAdding: .day, value: offset, to: start) else { continue }
            if (pages[date] ?? 0) >= dailyPageGoal {
                current += 1
                best = max(best, current)
            } else {
                current = 0
            }
        }
        return best
    }

    private var heatmapData: [(date: Date, pages: Int)] {
        let pages = dailyPages
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday + 5) % 7
        guard let thisMonday = calendar.date(byAdding: .day, value: -daysFromMonday, to: today),
              let startDate = calendar.date(byAdding: .day, value: -28, to: thisMonday) else { return [] }

        let totalDays = (calendar.dateComponents([.day], from: startDate, to: today).day ?? 0) + 1

        return (0..<totalDays).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: startDate) else { return nil }
            return (date, pages[date] ?? 0)
        }
    }

    private var readingBooks: [Book] {
        books.filter { !$0.isFinished }
    }

    // MARK: - Weekly Insights

    private var weeklyPages: Int {
        let pages = dailyPages
        let today = calendar.startOfDay(for: Date())
        return (0..<7).reduce(0) { sum, offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return sum }
            return sum + (pages[date] ?? 0)
        }
    }

    private var weeklyAverage: Double {
        Double(weeklyPages) / 7.0
    }

    private var mostActiveDay: String? {
        let pages = dailyPages
        let today = calendar.startOfDay(for: Date())
        let weekDays = (0..<7).compactMap { offset -> (Date, Int)? in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            return (date, pages[date] ?? 0)
        }
        guard let best = weekDays.max(by: { $0.1 < $1.1 }), best.1 > 0 else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: best.0)
    }

    private var projectedCompletion: (book: Book, daysLeft: Int)? {
        guard weeklyAverage > 0 else { return nil }
        guard let book = readingBooks.first else { return nil }
        let remaining = book.pagesRemaining
        let days = Int(ceil(Double(remaining) / weeklyAverage))
        return (book, days)
    }

    private var weeklyTrend: Double {
        let pages = dailyPages
        let today = calendar.startOfDay(for: Date())

        let thisWeek = (0..<7).reduce(0) { sum, offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return sum }
            return sum + (pages[date] ?? 0)
        }
        let lastWeek = (7..<14).reduce(0) { sum, offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return sum }
            return sum + (pages[date] ?? 0)
        }

        guard lastWeek > 0 else { return thisWeek > 0 ? 1.0 : 0.0 }
        return Double(thisWeek - lastWeek) / Double(lastWeek)
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    GoalRingSection(
                        todayPages: todayPages,
                        dailyPageGoal: dailyPageGoal,
                        todayProgress: todayProgress
                    )
                    StreakSection(
                        currentStreak: currentStreak,
                        bestStreak: bestStreak
                    )
                    GoalSettingSection(dailyPageGoal: $dailyPageGoal)
                    WeeklyInsightsSection(
                        weeklyPages: weeklyPages,
                        weeklyAverage: weeklyAverage,
                        mostActiveDay: mostActiveDay,
                        weeklyTrend: weeklyTrend,
                        projectedCompletion: projectedCompletion
                    )
                    HeatmapSection(
                        heatmapData: heatmapData,
                        dailyPageGoal: dailyPageGoal
                    )
                    BadgesCard(
                        allLogs: allLogs,
                        books: books,
                        currentStreak: currentStreak,
                        bestStreak: bestStreak,
                        dailyPageGoal: dailyPageGoal
                    )
                    ReminderCard(reminderManager: reminderManager)
                    CalendarTasksSection(
                        calendarManager: calendarManager,
                        readingBooks: readingBooks,
                        books: books,
                        dailyPageGoal: dailyPageGoal
                    )
                }
                .padding()
            }
            .navigationTitle("Goals")
            .task {
                await calendarManager.requestAccess()
                await reminderManager.checkAuthStatus()
                previousProgress = todayProgress
            }
            .onChange(of: todayProgress) { oldValue, newValue in
                if oldValue < 1.0 && newValue >= 1.0 {
                    HapticManager.goalAchieved()
                    showCelebration = true
                }
                if newValue >= 1.0 && calendarManager.isSetUp {
                    calendarManager.recordGoalCompletion(pages: todayPages, goal: dailyPageGoal)
                }
            }
            CelebrationView(
                isShowing: $showCelebration,
                emoji: "🎉",
                message: "Goal Complete!"
            )
        }
    }

}
