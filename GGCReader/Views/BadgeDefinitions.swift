import SwiftUI

struct Badge: Identifiable {
    let id: String
    let icon: String
    let name: LocalizedStringKey
    let requirement: LocalizedStringKey
    let isUnlocked: Bool
}

struct BadgeStats {
    let totalPages: Int
    let totalBooks: Int
    let finishedBooks: Int
    let daysRead: Int
    let bestSingleDay: Int
    let weekendDaysRead: Int
    let earlyBirdDays: Int
    let nightOwlDays: Int
    let distinctAuthors: Int
    let goalMetDays: Int
    let bestStreak: Int
}

func buildBadges(from stats: BadgeStats) -> [Badge] {
    [
        // --- Pages Read ---
        Badge(id: "first_page", icon: "📖",
              name: "First Page",
              requirement: "Read your first page",
              isUnlocked: stats.totalPages >= 1),
        Badge(id: "centurion", icon: "💯",
              name: "Centurion",
              requirement: "Read 100 pages total",
              isUnlocked: stats.totalPages >= 100),
        Badge(id: "bookworm", icon: "📚",
              name: "Bookworm",
              requirement: "Read 500 pages total",
              isUnlocked: stats.totalPages >= 500),
        Badge(id: "thousand", icon: "🏅",
              name: "Page Turner",
              requirement: "Read 1,000 pages total",
              isUnlocked: stats.totalPages >= 1000),
        Badge(id: "five_thousand", icon: "🔮",
              name: "Sage",
              requirement: "Read 5,000 pages total",
              isUnlocked: stats.totalPages >= 5000),
        Badge(id: "ten_thousand", icon: "🐉",
              name: "Legend",
              requirement: "Read 10,000 pages total",
              isUnlocked: stats.totalPages >= 10000),

        // --- Streaks ---
        Badge(id: "streak3", icon: "🔥",
              name: "On Fire",
              requirement: "3-day reading streak",
              isUnlocked: stats.bestStreak >= 3),
        Badge(id: "streak7", icon: "⚡️",
              name: "Unstoppable",
              requirement: "7-day reading streak",
              isUnlocked: stats.bestStreak >= 7),
        Badge(id: "streak30", icon: "👑",
              name: "Reading Royalty",
              requirement: "30-day reading streak",
              isUnlocked: stats.bestStreak >= 30),
        Badge(id: "streak100", icon: "💎",
              name: "Diamond",
              requirement: "100-day reading streak",
              isUnlocked: stats.bestStreak >= 100),
        Badge(id: "streak365", icon: "🏛️",
              name: "Eternal",
              requirement: "365-day reading streak",
              isUnlocked: stats.bestStreak >= 365),

        // --- Books Finished ---
        Badge(id: "first_book", icon: "🎓",
              name: "Graduate",
              requirement: "Finish your first book",
              isUnlocked: stats.finishedBooks >= 1),
        Badge(id: "three_books", icon: "🏆",
              name: "Hat Trick",
              requirement: "Finish 3 books",
              isUnlocked: stats.finishedBooks >= 3),
        Badge(id: "ten_books", icon: "🌟",
              name: "Bibliophile",
              requirement: "Finish 10 books",
              isUnlocked: stats.finishedBooks >= 10),
        Badge(id: "twentyfive_books", icon: "📕",
              name: "Scholar",
              requirement: "Finish 25 books",
              isUnlocked: stats.finishedBooks >= 25),
        Badge(id: "fifty_books", icon: "🧙",
              name: "Wizard",
              requirement: "Finish 50 books",
              isUnlocked: stats.finishedBooks >= 50),

        // --- Reading Days ---
        Badge(id: "week_reader", icon: "📅",
              name: "Dedicated",
              requirement: "Read on 7 different days",
              isUnlocked: stats.daysRead >= 7),
        Badge(id: "month_reader", icon: "🗓️",
              name: "Committed",
              requirement: "Read on 30 different days",
              isUnlocked: stats.daysRead >= 30),
        Badge(id: "hundred_days", icon: "🎯",
              name: "Centurion Days",
              requirement: "Read on 100 different days",
              isUnlocked: stats.daysRead >= 100),

        // --- Daily Records ---
        Badge(id: "fifty_day", icon: "🚀",
              name: "Speed Reader",
              requirement: "Read 50 pages in one day",
              isUnlocked: stats.bestSingleDay >= 50),
        Badge(id: "hundred_day", icon: "🌋",
              name: "Marathon",
              requirement: "Read 100 pages in one day",
              isUnlocked: stats.bestSingleDay >= 100),

        // --- Goals ---
        Badge(id: "goal_7", icon: "✅",
              name: "Goal Getter",
              requirement: "Meet daily goal 7 times",
              isUnlocked: stats.goalMetDays >= 7),
        Badge(id: "goal_30", icon: "🎖️",
              name: "Disciplined",
              requirement: "Meet daily goal 30 times",
              isUnlocked: stats.goalMetDays >= 30),

        // --- Collection ---
        Badge(id: "five_books_shelf", icon: "🗂️",
              name: "Collector",
              requirement: "Add 5 books to your shelf",
              isUnlocked: stats.totalBooks >= 5),
        Badge(id: "twenty_books_shelf", icon: "🏠",
              name: "Home Library",
              requirement: "Add 20 books to your shelf",
              isUnlocked: stats.totalBooks >= 20),
        Badge(id: "diverse_reader", icon: "🌍",
              name: "Explorer",
              requirement: "Read books by 5 different authors",
              isUnlocked: stats.distinctAuthors >= 5),

        // --- Time of Day ---
        Badge(id: "early_bird", icon: "🌅",
              name: "Early Bird",
              requirement: "Read before 9 AM on 3 days",
              isUnlocked: stats.earlyBirdDays >= 3),
        Badge(id: "night_owl", icon: "🦉",
              name: "Night Owl",
              requirement: "Read after 10 PM on 3 days",
              isUnlocked: stats.nightOwlDays >= 3),

        // --- Weekend ---
        Badge(id: "weekend_warrior", icon: "🏖️",
              name: "Weekend Warrior",
              requirement: "Read on 10 weekend days",
              isUnlocked: stats.weekendDaysRead >= 10),
    ]
}
