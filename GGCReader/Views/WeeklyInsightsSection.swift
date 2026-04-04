import SwiftUI

struct WeeklyInsightsSection: View {
    let weeklyPages: Int
    let weeklyAverage: Double
    let mostActiveDay: String?
    let weeklyTrend: Double
    let projectedCompletion: (book: Book, daysLeft: Int)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(.purple)
                Text("Weekly Insights")
                    .font(.headline)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                insightItem(
                    label: String(localized: "This Week"),
                    value: "\(weeklyPages)",
                    unit: String(localized: "pages"),
                    icon: "book.pages"
                )
                insightItem(
                    label: String(localized: "Daily Avg"),
                    value: String(format: "%.1f", weeklyAverage),
                    unit: String(localized: "pages"),
                    icon: "chart.bar"
                )
                if let day = mostActiveDay {
                    insightItem(
                        label: String(localized: "Most Active"),
                        value: day,
                        unit: "",
                        icon: "star.fill"
                    )
                }
                insightItem(
                    label: String(localized: "Trend"),
                    value: weeklyTrend > 0 ? "+\(Int(weeklyTrend * 100))%" : "\(Int(weeklyTrend * 100))%",
                    unit: String(localized: "vs last week"),
                    icon: weeklyTrend >= 0 ? "arrow.up.right" : "arrow.down.right"
                )
            }

            if let proj = projectedCompletion {
                HStack(spacing: 6) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Text("Finish \"\(proj.book.title)\" in ~\(proj.daysLeft) days")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                .padding(.top, 2)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func insightItem(label: String, value: String, unit: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.purple.opacity(0.7))
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.subheadline.bold())
                    .monospacedDigit()
                if unit.isEmpty {
                    Text(label)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(label) · \(unit)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
