import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query private var books: [Book]
    @Query(sort: \ReadingLog.date, order: .reverse) private var allLogs: [ReadingLog]
    @Query(sort: \ReadingSession.startTime, order: .reverse) private var allSessions: [ReadingSession]
    var storeManager = StoreManager.shared
    @State private var showingPaywall = false
    @State private var showingYearInReview = false

    private var totalBooks: Int { books.count }
    private var finishedBooks: Int { books.filter(\.isFinished).count }
    private var readingBooks: Int { books.filter { !$0.isFinished && $0.currentPage > 0 }.count }

    private var totalPagesRead: Int {
        allLogs.reduce(0) { $0 + $1.pagesRead }
    }

    private var totalReadingTime: Int {
        allSessions.reduce(0) { $0 + $1.durationSeconds }
    }

    private var thisWeekPages: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return allLogs.filter { $0.date >= weekAgo }.reduce(0) { $0 + $1.pagesRead }
    }

    private var todayPages: Int {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        return allLogs.filter { $0.date >= startOfDay }.reduce(0) { $0 + $1.pagesRead }
    }

    private var dailyAverage: Double {
        guard !allLogs.isEmpty else { return 0 }
        let cal = Calendar.current
        let earliest = allLogs.min(by: { $0.date < $1.date })?.date ?? Date()
        let days = max((cal.dateComponents([.day], from: cal.startOfDay(for: earliest), to: cal.startOfDay(for: Date())).day ?? 0) + 1, 1)
        return Double(totalPagesRead) / Double(days)
    }

    private var monthlyPages: Int {
        let startOfMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date())) ?? Date()
        return allLogs.filter { $0.date >= startOfMonth }.reduce(0) { $0 + $1.pagesRead }
    }

    private var monthlyBooksFinished: Int {
        let startOfMonth = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date())) ?? Date()
        return books.filter { $0.isFinished && ($0.dateFinished ?? $0.lastReadDate ?? .distantPast) >= startOfMonth }.count
    }

    private var monthlyDailyAverage: Double {
        let cal = Calendar.current
        let dayOfMonth = cal.component(.day, from: Date())
        guard dayOfMonth > 0 else { return 0 }
        return Double(monthlyPages) / Double(dayOfMonth)
    }

    // MARK: - Swift Charts Data

    @State private var trendPeriod: TrendPeriod = .month

    enum TrendPeriod: String, CaseIterable {
        case month = "30D"
        case quarter = "90D"
        case year = "1Y"

        var days: Int {
            switch self {
            case .month: 30
            case .quarter: 90
            case .year: 365
            }
        }
    }

    private func readingTrendData(period: TrendPeriod) -> [(date: Date, pagesPerDay: Double)] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let bucketSize = period == .year ? 7 : 1
        let totalBuckets = period.days / bucketSize

        // Pre-aggregate logs by day once (O(n) instead of O(buckets * n))
        var dailyMap: [Date: Int] = [:]
        guard let cutoff = cal.date(byAdding: .day, value: -period.days, to: today) else { return [] }
        for log in allLogs where log.date >= cutoff {
            let day = cal.startOfDay(for: log.date)
            dailyMap[day, default: 0] += log.pagesRead
        }

        return (0..<totalBuckets).compactMap { bucket in
            let endOffset = bucket * bucketSize
            guard let endDate = cal.date(byAdding: .day, value: -endOffset, to: today) else { return nil }

            var total = 0
            for dayOffset in 0..<bucketSize {
                guard let date = cal.date(byAdding: .day, value: -(endOffset + dayOffset), to: today) else { continue }
                total += dailyMap[date] ?? 0
            }
            let avg = Double(total) / Double(bucketSize)
            return (endDate, avg)
        }.reversed()
    }

    private var genreDistribution: [(genre: String, count: Int)] {
        let genres = books.filter(\.isFinished).map(\.genre).filter { !$0.isEmpty }
        let counts = Dictionary(grouping: genres, by: { $0 }).mapValues(\.count)
        return counts.sorted { $0.value > $1.value }.prefix(6).map { ($0.key, $0.value) }
    }

    // MARK: - Reading Time Analysis

    private struct HeatmapCell: Identifiable {
        let id = UUID()
        let dayIndex: Int  // 0=Mon ... 6=Sun
        let hour: Int      // 0-23
        let count: Int
    }

    private var sessionGrid: [[Int]] {
        let cal = Calendar.current
        var grid = [[Int]](repeating: [Int](repeating: 0, count: 24), count: 7)
        for session in allSessions {
            let weekday = (cal.component(.weekday, from: session.startTime) + 5) % 7
            let hour = cal.component(.hour, from: session.startTime)
            grid[weekday][hour] += 1
        }
        return grid
    }

    private var bestReadingTime: (day: String, hour: String)? {
        let grid = sessionGrid
        var bestDay = 0, bestHour = 0, bestCount = 0
        for day in 0..<7 {
            for hour in 0..<24 {
                if grid[day][hour] > bestCount {
                    bestCount = grid[day][hour]
                    bestDay = day
                    bestHour = hour
                }
            }
        }
        guard bestCount > 0 else { return nil }
        // Use locale-aware weekday names (weekdaySymbols: [Sun, Mon, ..., Sat]; grid: 0=Mon…6=Sun)
        let weekdaySymbols = Calendar.current.weekdaySymbols
        let dayName = weekdaySymbols[(bestDay + 1) % 7]
        var comps = DateComponents()
        comps.hour = bestHour
        comps.minute = 0
        let hourDate = Calendar.current.date(from: comps) ?? Date()
        let df = DateFormatter()
        df.dateFormat = DateFormatter.dateFormat(fromTemplate: "ha", options: 0, locale: .current)
        return (dayName, df.string(from: hourDate))
    }

    private var readingTimeHeatmap: some View {
        let grid = sessionGrid
        let maxCount = max(grid.flatMap { $0 }.max() ?? 1, 1)
        // Locale-aware very short weekday labels, Mon-Sun order (grid index 0=Mon, 6=Sun)
        let allSymbols = Calendar.current.veryShortStandaloneWeekdaySymbols
        let days = (1..<7).map { allSymbols[$0] } + [allSymbols[0]]

        return VStack(spacing: 2) {
            HStack(spacing: 0) {
                Text("")
                    .frame(width: 16)
                ForEach([0, 4, 8, 12, 16, 20], id: \.self) { h in
                    Text("\(h)")
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            ForEach(0..<7, id: \.self) { day in
                HStack(spacing: 2) {
                    Text(days[day])
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .frame(width: 16)
                    ForEach(0..<24, id: \.self) { hour in
                        let count = grid[day][hour]
                        let intensity = Double(count) / Double(maxCount)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(count == 0 ? Color.gray.opacity(0.1) : Color.orange.opacity(0.2 + intensity * 0.8))
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
    }

    private var last7DaysData: [(String, Int)] {
        let calendar = Calendar.current
        return (0..<7).reversed().compactMap { daysAgo in
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date()) else { return nil }
            let start = calendar.startOfDay(for: date)
            guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return nil }
            let pages = allLogs
                .filter { $0.date >= start && $0.date < end }
                .reduce(0) { $0 + $1.pagesRead }
            let label = date.formatted(.dateTime.weekday(.abbreviated))
            return (label, pages)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Year in Review
                Button {
                    showingYearInReview = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.title2)
                            .foregroundStyle(.yellow)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(String(Calendar.current.component(.year, from: Date()))) Year in Reading")
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text("Your reading journey, wrapped")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .padding()
                    .background(
                        LinearGradient(colors: [.indigo, .purple], startPoint: .leading, endPoint: .trailing)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    )
                }
                .buttonStyle(.plain)
                .fullScreenCover(isPresented: $showingYearInReview) {
                    YearInReviewView(year: Calendar.current.component(.year, from: Date()))
                }

                // Overview cards
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    StatCard(title: "Total Books", value: "\(totalBooks)", icon: "books.vertical", color: .blue)
                    StatCard(title: "Finished", value: "\(finishedBooks)", icon: "checkmark.circle", color: .green)
                    StatCard(title: "Reading", value: "\(readingBooks)", icon: "book", color: .orange)
                    StatCard(title: "Pages Read", value: "\(totalPagesRead)", icon: "doc.text", color: .purple)
                    StatCard(title: "Today", value: "\(todayPages) pages", icon: "calendar", color: .red)
                    StatCard(title: "This Week", value: "\(thisWeekPages) pages", icon: "calendar.badge.clock", color: .teal)
                }

                // Weekly chart
                VStack(alignment: .leading, spacing: 12) {
                    Text("Last 7 Days")
                        .font(.headline)

                    let maxPages = max(last7DaysData.map(\.1).max() ?? 1, 1)
                    HStack(alignment: .bottom, spacing: 8) {
                        ForEach(last7DaysData, id: \.0) { day, pages in
                            VStack(spacing: 4) {
                                Text("\(pages)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.blue.gradient)
                                    .frame(height: max(CGFloat(pages) / CGFloat(maxPages) * 120, 4))
                                Text(day)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(height: 160)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))

                // Monthly overview (Pro)
                if storeManager.isPro {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("This Month")
                                .font(.headline)
                            Spacer()
                            Text(Date().formatted(.dateTime.month(.wide).year()))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        HStack(spacing: 0) {
                            VStack(spacing: 4) {
                                Text("\(monthlyPages)")
                                    .font(.title2.bold())
                                    .foregroundStyle(.purple)
                                Text("pages")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)

                            VStack(spacing: 4) {
                                Text("\(monthlyBooksFinished)")
                                    .font(.title2.bold())
                                    .foregroundStyle(.green)
                                Text("books finished")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)

                            VStack(spacing: 4) {
                                Text(String(format: "%.1f", monthlyDailyAverage))
                                    .font(.title2.bold())
                                    .foregroundStyle(.orange)
                                Text("avg pages/day")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                }

                // Reading speed
                if storeManager.isPro {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Reading Speed")
                            .font(.headline)

                        HStack(spacing: 24) {
                            VStack {
                                Text(String(format: "%.1f", dailyAverage))
                                    .font(.title.bold())
                                    .foregroundStyle(.blue)
                                Text("pages/day")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            if totalReadingTime > 0 {
                                VStack {
                                    Text(formatDuration(totalReadingTime))
                                        .font(.title.bold())
                                        .foregroundStyle(.green)
                                    Text("total reading")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))

                    // Reading Speed Trend Chart
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Reading Trend")
                                .font(.headline)
                            Spacer()
                            Picker("Period", selection: $trendPeriod) {
                                ForEach(TrendPeriod.allCases, id: \.self) { period in
                                    Text(period.rawValue).tag(period)
                                }
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 160)
                        }

                        let trendData = readingTrendData(period: trendPeriod)
                        if !trendData.isEmpty {
                            Chart(trendData, id: \.date) { item in
                                LineMark(
                                    x: .value("Date", item.date),
                                    y: .value("Pages/Day", item.pagesPerDay)
                                )
                                .foregroundStyle(.blue.gradient)
                                .interpolationMethod(.catmullRom)

                                AreaMark(
                                    x: .value("Date", item.date),
                                    y: .value("Pages/Day", item.pagesPerDay)
                                )
                                .foregroundStyle(.blue.opacity(0.1))
                                .interpolationMethod(.catmullRom)
                            }
                            .chartYAxisLabel("pages/day")
                            .frame(height: 180)
                        } else {
                            Text("Not enough data yet")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical)
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))

                    // Genre Distribution Chart
                    if !genreDistribution.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Genre Distribution")
                                .font(.headline)

                            Chart(genreDistribution, id: \.genre) { item in
                                SectorMark(
                                    angle: .value("Count", item.count),
                                    innerRadius: .ratio(0.5),
                                    angularInset: 1.5
                                )
                                .foregroundStyle(by: .value("Genre", item.genre))
                                .cornerRadius(4)
                            }
                            .frame(height: 200)
                            .chartLegend(position: .bottom, spacing: 8)
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }

                    // Reading Time Heatmap
                    if !allSessions.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("When You Read")
                                .font(.headline)

                            readingTimeHeatmap
                                .frame(height: 200)

                            if let bestTime = bestReadingTime {
                                HStack(spacing: 8) {
                                    Image(systemName: "clock.fill")
                                        .foregroundStyle(.orange)
                                    Text("You read most on **\(bestTime.day)** around **\(bestTime.hour)**")
                                        .font(.caption)
                                }
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                } else {
                    Button {
                        showingPaywall = true
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: "crown.fill")
                                .font(.title3)
                                .foregroundStyle(.yellow)
                            Text("Reading Speed & More")
                                .font(.subheadline.bold())
                                .foregroundStyle(.primary)
                            Text("Upgrade to Pro for advanced stats")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .sheet(isPresented: $showingPaywall) {
                        PaywallView()
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Statistics")
    }

    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

struct StatCard: View {
    let title: LocalizedStringKey
    let value: LocalizedStringKey
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.title3)
                Spacer()
            }
            Text(value)
                .font(.title2.bold())
                .monospacedDigit()
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
