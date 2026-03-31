import SwiftUI
import SwiftData

struct Badge: Identifiable {
    let id: String
    let icon: String
    let name: LocalizedStringKey
    let requirement: LocalizedStringKey
    let isUnlocked: Bool
}

struct BadgesCard: View {
    let allLogs: [ReadingLog]
    let books: [Book]
    let currentStreak: Int
    let bestStreak: Int
    let dailyPageGoal: Int

    @State private var selectedBadge: Badge?

    private var totalPages: Int {
        allLogs.reduce(0) { $0 + $1.pagesRead }
    }

    private var totalBooks: Int {
        books.count
    }

    private var finishedBooks: Int {
        books.filter(\.isFinished).count
    }

    private var daysRead: Int {
        let dates = Set(allLogs.map { Calendar.current.startOfDay(for: $0.date) })
        return dates.count
    }

    private var bestSingleDay: Int {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: allLogs) { cal.startOfDay(for: $0.date) }
        return grouped.values.map { $0.reduce(0) { $0 + $1.pagesRead } }.max() ?? 0
    }

    private var weekendDaysRead: Int {
        let cal = Calendar.current
        let weekendDates = Set(allLogs.compactMap { log -> Date? in
            let day = cal.startOfDay(for: log.date)
            return cal.isDateInWeekend(day) ? day : nil
        })
        return weekendDates.count
    }

    private var earlyBirdDays: Int {
        let cal = Calendar.current
        let morningDates = Set(allLogs.compactMap { log -> Date? in
            let hour = cal.component(.hour, from: log.date)
            return hour < 9 ? cal.startOfDay(for: log.date) : nil
        })
        return morningDates.count
    }

    private var nightOwlDays: Int {
        let cal = Calendar.current
        let nightDates = Set(allLogs.compactMap { log -> Date? in
            let hour = cal.component(.hour, from: log.date)
            return (hour >= 22 || hour < 5) ? cal.startOfDay(for: log.date) : nil
        })
        return nightDates.count
    }

    private var distinctAuthors: Int {
        Set(books.map(\.author)).subtracting([""]).count
    }

    private var goalMetDays: Int {
        guard dailyPageGoal > 0 else { return 0 }
        let cal = Calendar.current
        let grouped = Dictionary(grouping: allLogs) { cal.startOfDay(for: $0.date) }
        return grouped.values.filter { logs in
            logs.reduce(0) { $0 + $1.pagesRead } >= dailyPageGoal
        }.count
    }

    private var badges: [Badge] {
        [
            // --- Pages Read ---
            Badge(id: "first_page", icon: "📖",
                  name: "First Page",
                  requirement: "Read your first page",
                  isUnlocked: totalPages >= 1),
            Badge(id: "centurion", icon: "💯",
                  name: "Centurion",
                  requirement: "Read 100 pages total",
                  isUnlocked: totalPages >= 100),
            Badge(id: "bookworm", icon: "📚",
                  name: "Bookworm",
                  requirement: "Read 500 pages total",
                  isUnlocked: totalPages >= 500),
            Badge(id: "thousand", icon: "🏅",
                  name: "Page Turner",
                  requirement: "Read 1,000 pages total",
                  isUnlocked: totalPages >= 1000),
            Badge(id: "five_thousand", icon: "🔮",
                  name: "Sage",
                  requirement: "Read 5,000 pages total",
                  isUnlocked: totalPages >= 5000),
            Badge(id: "ten_thousand", icon: "🐉",
                  name: "Legend",
                  requirement: "Read 10,000 pages total",
                  isUnlocked: totalPages >= 10000),

            // --- Streaks ---
            Badge(id: "streak3", icon: "🔥",
                  name: "On Fire",
                  requirement: "3-day reading streak",
                  isUnlocked: bestStreak >= 3),
            Badge(id: "streak7", icon: "⚡️",
                  name: "Unstoppable",
                  requirement: "7-day reading streak",
                  isUnlocked: bestStreak >= 7),
            Badge(id: "streak30", icon: "👑",
                  name: "Reading Royalty",
                  requirement: "30-day reading streak",
                  isUnlocked: bestStreak >= 30),
            Badge(id: "streak100", icon: "💎",
                  name: "Diamond",
                  requirement: "100-day reading streak",
                  isUnlocked: bestStreak >= 100),
            Badge(id: "streak365", icon: "🏛️",
                  name: "Eternal",
                  requirement: "365-day reading streak",
                  isUnlocked: bestStreak >= 365),

            // --- Books Finished ---
            Badge(id: "first_book", icon: "🎓",
                  name: "Graduate",
                  requirement: "Finish your first book",
                  isUnlocked: finishedBooks >= 1),
            Badge(id: "three_books", icon: "🏆",
                  name: "Hat Trick",
                  requirement: "Finish 3 books",
                  isUnlocked: finishedBooks >= 3),
            Badge(id: "ten_books", icon: "🌟",
                  name: "Bibliophile",
                  requirement: "Finish 10 books",
                  isUnlocked: finishedBooks >= 10),
            Badge(id: "twentyfive_books", icon: "📕",
                  name: "Scholar",
                  requirement: "Finish 25 books",
                  isUnlocked: finishedBooks >= 25),
            Badge(id: "fifty_books", icon: "🧙",
                  name: "Wizard",
                  requirement: "Finish 50 books",
                  isUnlocked: finishedBooks >= 50),

            // --- Reading Days ---
            Badge(id: "week_reader", icon: "📅",
                  name: "Dedicated",
                  requirement: "Read on 7 different days",
                  isUnlocked: daysRead >= 7),
            Badge(id: "month_reader", icon: "🗓️",
                  name: "Committed",
                  requirement: "Read on 30 different days",
                  isUnlocked: daysRead >= 30),
            Badge(id: "hundred_days", icon: "🎯",
                  name: "Centurion Days",
                  requirement: "Read on 100 different days",
                  isUnlocked: daysRead >= 100),

            // --- Daily Records ---
            Badge(id: "fifty_day", icon: "🚀",
                  name: "Speed Reader",
                  requirement: "Read 50 pages in one day",
                  isUnlocked: bestSingleDay >= 50),
            Badge(id: "hundred_day", icon: "🌋",
                  name: "Marathon",
                  requirement: "Read 100 pages in one day",
                  isUnlocked: bestSingleDay >= 100),

            // --- Goals ---
            Badge(id: "goal_7", icon: "✅",
                  name: "Goal Getter",
                  requirement: "Meet daily goal 7 times",
                  isUnlocked: goalMetDays >= 7),
            Badge(id: "goal_30", icon: "🎖️",
                  name: "Disciplined",
                  requirement: "Meet daily goal 30 times",
                  isUnlocked: goalMetDays >= 30),

            // --- Collection ---
            Badge(id: "five_books_shelf", icon: "🗂️",
                  name: "Collector",
                  requirement: "Add 5 books to your shelf",
                  isUnlocked: totalBooks >= 5),
            Badge(id: "twenty_books_shelf", icon: "🏠",
                  name: "Home Library",
                  requirement: "Add 20 books to your shelf",
                  isUnlocked: totalBooks >= 20),
            Badge(id: "diverse_reader", icon: "🌍",
                  name: "Explorer",
                  requirement: "Read books by 5 different authors",
                  isUnlocked: distinctAuthors >= 5),

            // --- Time of Day ---
            Badge(id: "early_bird", icon: "🌅",
                  name: "Early Bird",
                  requirement: "Read before 9 AM on 3 days",
                  isUnlocked: earlyBirdDays >= 3),
            Badge(id: "night_owl", icon: "🦉",
                  name: "Night Owl",
                  requirement: "Read after 10 PM on 3 days",
                  isUnlocked: nightOwlDays >= 3),

            // --- Weekend ---
            Badge(id: "weekend_warrior", icon: "🏖️",
                  name: "Weekend Warrior",
                  requirement: "Read on 10 weekend days",
                  isUnlocked: weekendDaysRead >= 10),
        ]
    }

    private var unlockedCount: Int {
        badges.filter(\.isUnlocked).count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "medal.fill")
                    .foregroundStyle(.yellow)
                Text("Badges")
                    .font(.headline)
                Spacer()
                Text("\(unlockedCount)/\(badges.count)")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }

            // Selected badge detail
            if let badge = selectedBadge {
                HStack(spacing: 8) {
                    Text(badge.icon)
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(badge.name)
                            .font(.caption.bold())
                        Text(badge.requirement)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if badge.isUnlocked {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
                .padding(10)
                .background(Color.yellow.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 5), spacing: 10) {
                ForEach(badges) { badge in
                    badgeItem(badge)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func badgeItem(_ badge: Badge) -> some View {
        VStack(spacing: 4) {
            Text(badge.isUnlocked ? badge.icon : "🔒")
                .font(.system(size: 28))
                .opacity(badge.isUnlocked ? 1 : 0.4)
                .scaleEffect(badge.isUnlocked ? 1 : 0.85)
            Text(badge.name)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(badge.isUnlocked ? .primary : .secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                if selectedBadge?.id == badge.id {
                    selectedBadge = nil
                } else {
                    selectedBadge = badge
                    HapticManager.selection()
                }
            }
        }
    }
}
