import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct ReadingProvider: TimelineProvider {
    func placeholder(in context: Context) -> ReadingEntry {
        ReadingEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (ReadingEntry) -> Void) {
        let data = WidgetData.load() ?? .placeholder
        completion(ReadingEntry(date: Date(), data: data))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ReadingEntry>) -> Void) {
        let data = WidgetData.load() ?? .placeholder
        let entry = ReadingEntry(date: Date(), data: data)
        // Refresh every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct ReadingEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}

// MARK: - Book Progress Widget

struct BookProgressWidget: Widget {
    let kind = "BookProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ReadingProvider()) { entry in
            BookProgressView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Current Book")
        .description("Track your current reading progress")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct BookProgressView: View {
    @Environment(\.widgetFamily) var family
    let entry: ReadingEntry

    var body: some View {
        if let book = entry.data.currentBook {
            switch family {
            case .systemMedium:
                mediumBookView(book)
            default:
                smallBookView(book)
            }
        } else {
            VStack(spacing: 6) {
                Image(systemName: "book.closed")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("No book in progress")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func smallBookView(_ book: WidgetBookData) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                WidgetProgressRing(progress: book.progressPercentage, colorName: book.colorName, size: 44)
                Spacer()
                Text("\(Int(book.progressPercentage * 100))%")
                    .font(.title3.bold())
                    .monospacedDigit()
                    .foregroundStyle(colorFor(book.colorName))
            }

            Text(book.title)
                .font(.caption.bold())
                .lineLimit(2)

            Text("p.\(book.currentPage)/\(book.totalPages)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func mediumBookView(_ book: WidgetBookData) -> some View {
        HStack(spacing: 16) {
            WidgetProgressRing(progress: book.progressPercentage, colorName: book.colorName, size: 64)

            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)
                Text(book.author)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Spacer()

                HStack {
                    Label("p.\(book.currentPage)/\(book.totalPages)", systemImage: "bookmark")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(book.totalPages - book.currentPage) left")
                        .font(.caption2.bold())
                        .foregroundStyle(colorFor(book.colorName))
                }
            }
        }
    }
}

// MARK: - Daily Goal Widget

struct DailyGoalWidget: Widget {
    let kind = "DailyGoalWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ReadingProvider()) { entry in
            DailyGoalView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Daily Goal")
        .description("Track your daily reading goal")
        .supportedFamilies([.systemSmall])
    }
}

struct DailyGoalView: View {
    let entry: ReadingEntry

    private var progress: Double {
        guard entry.data.dailyGoal > 0 else { return 0 }
        return min(Double(entry.data.todayPages) / Double(entry.data.dailyGoal), 1.0)
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(.quaternary, lineWidth: 8)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        progress >= 1.0 ? Color.green : Color.blue,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text("\(entry.data.todayPages)")
                        .font(.title2.bold())
                        .monospacedDigit()
                    Text("/\(entry.data.dailyGoal)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 80, height: 80)

            if progress >= 1.0 {
                Label("Goal Complete!", systemImage: "checkmark.circle.fill")
                    .font(.caption2.bold())
                    .foregroundStyle(.green)
            } else {
                Text("\(entry.data.dailyGoal - entry.data.todayPages) pages to go")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Lock Screen Widgets (Accessory)

struct StreakAccessoryWidget: Widget {
    let kind = "StreakAccessoryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ReadingProvider()) { entry in
            StreakAccessoryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Reading Streak")
        .description("Your current reading streak")
        .supportedFamilies([.accessoryCircular, .accessoryInline, .accessoryRectangular])
    }
}

struct StreakAccessoryView: View {
    @Environment(\.widgetFamily) var family
    let entry: ReadingEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            circularView
        case .accessoryInline:
            inlineView
        case .accessoryRectangular:
            rectangularView
        default:
            circularView
        }
    }

    private var circularView: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Image(systemName: "flame.fill")
                    .font(.caption)
                Text("\(entry.data.currentStreak)")
                    .font(.title3.bold())
                    .monospacedDigit()
            }
        }
    }

    private var inlineView: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
            Text("\(entry.data.currentStreak) day streak · \(entry.data.todayPages)/\(entry.data.dailyGoal) pages")
        }
    }

    private var rectangularView: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                    Text("\(entry.data.currentStreak) day streak")
                        .font(.headline)
                }
                Text("Today: \(entry.data.todayPages)/\(entry.data.dailyGoal) pages")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}

// MARK: - Progress Ring

struct WidgetProgressRing: View {
    let progress: Double
    let colorName: String
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(.quaternary, lineWidth: size * 0.1)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    colorFor(colorName),
                    style: StrokeStyle(lineWidth: size * 0.1, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Widget Bundle

@main
struct GGCReaderWidgetBundle: WidgetBundle {
    var body: some Widget {
        BookProgressWidget()
        DailyGoalWidget()
        StreakAccessoryWidget()
    }
}
