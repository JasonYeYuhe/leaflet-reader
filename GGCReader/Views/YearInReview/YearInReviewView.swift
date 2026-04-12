import SwiftUI
import SwiftData

struct YearInReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ReadingLog.date) private var allLogs: [ReadingLog]
    @Query(sort: \Book.dateAdded) private var allBooks: [Book]
    @Query(sort: \ReadingSession.startTime) private var allSessions: [ReadingSession]

    let year: Int

    @State private var currentPage = 0
    private let totalPages = 6

    private var yearLogs: [ReadingLog] {
        allLogs.filter { Calendar.current.component(.year, from: $0.date) == year }
    }

    private var yearBooks: [Book] {
        allBooks.filter {
            guard let finished = $0.dateFinished ?? $0.lastReadDate else { return false }
            return Calendar.current.component(.year, from: finished) == year && $0.isFinished
        }
    }

    private var yearSessions: [ReadingSession] {
        allSessions.filter { Calendar.current.component(.year, from: $0.startTime) == year }
    }

    // MARK: - Stats

    private var totalPagesRead: Int {
        yearLogs.reduce(0) { $0 + $1.pagesRead }
    }

    private var totalBooksFinished: Int {
        yearBooks.count
    }

    private var totalReadingMinutes: Int {
        yearSessions.reduce(0) { $0 + $1.durationSeconds } / 60
    }

    private var favoriteAuthor: String? {
        let authors = yearBooks.map(\.author).filter { !$0.isEmpty }
        let counts = Dictionary(grouping: authors, by: { $0 }).mapValues(\.count)
        return counts.max(by: { $0.value < $1.value })?.key
    }

    private var monthlyData: [(month: String, pages: Int)] {
        let cal = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return (1...12).map { month in
            let pages = yearLogs.filter {
                cal.component(.month, from: $0.date) == month
            }.reduce(0) { $0 + $1.pagesRead }
            let date = cal.date(from: DateComponents(year: year, month: month, day: 1))!
            return (formatter.string(from: date), pages)
        }
    }

    private var bestMonth: (month: String, pages: Int)? {
        monthlyData.max(by: { $0.pages < $1.pages })
    }

    private var longestStreak: Int {
        let cal = Calendar.current
        let startOfYear = cal.date(from: DateComponents(year: year, month: 1, day: 1))!
        let endOfYear = cal.date(from: DateComponents(year: year, month: 12, day: 31))!
        let totalDays = (cal.dateComponents([.day], from: startOfYear, to: endOfYear).day ?? 0) + 1

        var daySet = Set<Date>()
        for log in yearLogs {
            daySet.insert(cal.startOfDay(for: log.date))
        }

        var best = 0
        var current = 0
        for offset in 0..<totalDays {
            guard let date = cal.date(byAdding: .day, value: offset, to: startOfYear) else { continue }
            if daySet.contains(date) {
                current += 1
                best = max(best, current)
            } else {
                current = 0
            }
        }
        return best
    }

    private var topGenres: [(genre: String, count: Int)] {
        let genres = yearBooks.map(\.genre).filter { !$0.isEmpty }
        let counts = Dictionary(grouping: genres, by: { $0 }).mapValues(\.count)
        return counts.sorted { $0.value > $1.value }.prefix(3).map { ($0.key, $0.value) }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentPage) {
                titlePage.tag(0)
                booksPage.tag(1)
                pagesPage.tag(2)
                monthlyPage.tag(3)
                highlightsPage.tag(4)
                summaryPage.tag(5)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            // Close button
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    Spacer()
                }
                .padding()
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Pages

    private var titlePage: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("\(String(year))")
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("Year in Reading")
                .font(.title.bold())
                .foregroundStyle(.white.opacity(0.8))
            Text("Your reading journey, wrapped")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
            Spacer()
            Text("Swipe to explore")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.3))
                .padding(.bottom, 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(colors: [.indigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
    }

    private var booksPage: some View {
        VStack(spacing: 32) {
            Spacer()
            Text("\(totalBooksFinished)")
                .font(.system(size: 80, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("Books Finished")
                .font(.title2.bold())
                .foregroundStyle(.white.opacity(0.8))

            if let author = favoriteAuthor {
                VStack(spacing: 4) {
                    Text("Favorite Author")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                    Text(author)
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                }
                .padding(.top, 8)
            }

            if !topGenres.isEmpty {
                VStack(spacing: 8) {
                    Text("Top Genres")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                    ForEach(topGenres, id: \.genre) { genre, count in
                        HStack {
                            Text(genre)
                                .font(.subheadline)
                            Spacer()
                            Text("\(count) books")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 40)
                    }
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
    }

    private var pagesPage: some View {
        VStack(spacing: 32) {
            Spacer()
            Text("\(totalPagesRead)")
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
            Text("Pages Read")
                .font(.title2.bold())
                .foregroundStyle(.white.opacity(0.8))

            HStack(spacing: 40) {
                VStack(spacing: 4) {
                    Text("\(totalPagesRead / max(365, 1))")
                        .font(.title.bold())
                    Text("avg/day")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
                if totalReadingMinutes > 0 {
                    VStack(spacing: 4) {
                        Text("\(totalReadingMinutes / 60)h \(totalReadingMinutes % 60)m")
                            .font(.title.bold())
                        Text("total time")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
            .foregroundStyle(.white)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(colors: [.green, .teal], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
    }

    private var monthlyPage: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("Monthly Breakdown")
                .font(.title2.bold())
                .foregroundStyle(.white)

            // Bar chart
            let maxPages = max(monthlyData.map(\.pages).max() ?? 1, 1)
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(monthlyData, id: \.month) { month, pages in
                    VStack(spacing: 4) {
                        if pages > 0 {
                            Text("\(pages)")
                                .font(.system(size: 8))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        RoundedRectangle(cornerRadius: 3)
                            .fill(.white.opacity(pages > 0 ? 0.8 : 0.15))
                            .frame(height: max(CGFloat(pages) / CGFloat(maxPages) * 140, 4))
                        Text(month)
                            .font(.system(size: 9))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 200)

            if let best = bestMonth, best.pages > 0 {
                VStack(spacing: 4) {
                    Text("Best Month")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                    Text("\(best.month) — \(best.pages) pages")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
    }

    private var highlightsPage: some View {
        VStack(spacing: 32) {
            Spacer()
            Text("Highlights")
                .font(.title2.bold())
                .foregroundStyle(.white)

            VStack(spacing: 20) {
                highlightRow(icon: "flame.fill", value: "\(longestStreak)", label: "Day Longest Streak")
                highlightRow(icon: "book.closed.fill", value: "\(allBooks.filter { Calendar.current.component(.year, from: $0.dateAdded) == year }.count)", label: "Books Added")

                let ratedBooks = yearBooks.filter { $0.rating != nil }
                if !ratedBooks.isEmpty {
                    let avgRating = Double(ratedBooks.compactMap(\.rating).reduce(0, +)) / Double(ratedBooks.count)
                    highlightRow(icon: "star.fill", value: String(format: "%.1f", avgRating), label: "Average Rating")
                }

                let totalNotes = yearBooks.flatMap(\.notes).count
                if totalNotes > 0 {
                    highlightRow(icon: "note.text", value: "\(totalNotes)", label: "Notes & Quotes")
                }
            }
            .padding(.horizontal, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
    }

    private func highlightRow(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.white.opacity(0.8))
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
            Spacer()
        }
    }

    private var summaryPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "books.vertical.fill")
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.8))

            Text("Your \(String(year)) in Reading")
                .font(.title2.bold())
                .foregroundStyle(.white)

            VStack(spacing: 8) {
                Text("\(totalBooksFinished) books · \(totalPagesRead) pages")
                    .font(.headline)
                if let author = favoriteAuthor {
                    Text("Favorite author: \(author)")
                        .font(.subheadline)
                }
                Text("\(longestStreak)-day best streak")
                    .font(.subheadline)
            }
            .foregroundStyle(.white.opacity(0.8))

            // Branding
            HStack(spacing: 4) {
                Image(systemName: "book.closed.fill")
                    .font(.caption)
                Text("æstel")
                    .font(.subheadline.bold())
            }
            .foregroundStyle(.white.opacity(0.5))
            .padding(.top, 16)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.white.opacity(0.2))
            .foregroundStyle(.white)
            .padding(.horizontal, 40)
            .padding(.bottom, 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(colors: [.indigo, .blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
    }
}
