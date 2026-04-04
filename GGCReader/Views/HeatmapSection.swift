import SwiftUI

struct HeatmapSection: View {
    let heatmapData: [(date: Date, pages: Int)]
    let dailyPageGoal: Int

    private let calendar = Calendar.current

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reading Activity")
                .font(.headline)

            let data = heatmapData
            let weekdaySymbols = calendar.shortWeekdaySymbols
            let headers = Array(weekdaySymbols[1...]) + [weekdaySymbols[0]]

            HStack(spacing: 4) {
                ForEach(headers, id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            let weeks = stride(from: 0, to: data.count, by: 7).map { start in
                Array(data[start..<min(start + 7, data.count)])
            }

            ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                HStack(spacing: 4) {
                    ForEach(Array(week.enumerated()), id: \.offset) { _, day in
                        let ratio = dailyPageGoal > 0 ? Double(day.pages) / Double(dailyPageGoal) : 0
                        let isToday = calendar.isDateInToday(day.date)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(colorForRatio(ratio))
                            .aspectRatio(1, contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .overlay {
                                if day.pages > 0 {
                                    Text("\(day.pages)")
                                        .font(.system(size: 9, weight: .medium, design: .rounded))
                                        .foregroundStyle(ratio >= 0.5 ? .white : .primary.opacity(0.6))
                                        .minimumScaleFactor(0.5)
                                        .lineLimit(1)
                                }
                            }
                            .overlay {
                                if isToday {
                                    RoundedRectangle(cornerRadius: 4)
                                        .strokeBorder(.primary.opacity(0.5), lineWidth: 1.5)
                                }
                            }
                    }
                    if week.count < 7 {
                        ForEach(0..<(7 - week.count), id: \.self) { _ in
                            Color.clear
                                .aspectRatio(1, contentMode: .fit)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }

            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 12, height: 12)
                    Text("0")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.green.opacity(0.3))
                        .frame(width: 12, height: 12)
                    Text("<50%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.green.opacity(0.6))
                        .frame(width: 12, height: 12)
                    Text("<100%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                    Image(systemName: "checkmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.green)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Reading activity heatmap showing \(heatmapData.count) days"))
        .accessibilityValue(Text("\(heatmapData.filter { $0.pages > 0 }.count) active days"))
    }

    private func colorForRatio(_ ratio: Double) -> Color {
        if ratio <= 0 { return Color.gray.opacity(0.15) }
        if ratio < 0.5 { return Color.green.opacity(0.3) }
        if ratio < 1.0 { return Color.green.opacity(0.6) }
        return Color.green
    }
}
