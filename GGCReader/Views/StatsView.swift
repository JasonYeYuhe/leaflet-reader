import SwiftUI
import SwiftData

struct StatsView: View {
    @Query private var books: [Book]
    @Query(sort: \ReadingLog.date, order: .reverse) private var allLogs: [ReadingLog]
    @Query(sort: \ReadingSession.startTime, order: .reverse) private var allSessions: [ReadingSession]
    var storeManager = StoreManager.shared
    @State private var showingPaywall = false

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
