import SwiftUI

struct GoalRingSection: View {
    let todayPages: Int
    let dailyPageGoal: Int
    let todayProgress: Double

    var body: some View {
        VStack(spacing: 16) {
            ProgressRingView(
                progress: todayProgress,
                color: todayProgress >= 1.0 ? .green : .blue,
                size: 120
            )

            VStack(spacing: 4) {
                Text("\(todayPages)/\(dailyPageGoal)")
                    .font(.title.bold())
                    .monospacedDigit()
                if todayProgress >= 1.0 {
                    Text("Goal Complete!")
                        .font(.subheadline.bold())
                        .foregroundStyle(.green)
                } else {
                    Text("\(dailyPageGoal - todayPages) pages to go")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            todayProgress >= 1.0
                ? Text("Daily reading goal complete. \(todayPages) of \(dailyPageGoal) pages read today.")
                : Text("Daily reading goal: \(todayPages) of \(dailyPageGoal) pages, \(Int(todayProgress * 100)) percent complete.")
        )
    }
}

struct GoalSettingSection: View {
    @Binding var dailyPageGoal: Int

    var body: some View {
        VStack(spacing: 12) {
            Text("Daily Goal")
                .font(.headline)

            HStack(spacing: 8) {
                Button {
                    if dailyPageGoal > 5 { dailyPageGoal -= 5 }
                } label: {
                    Text("-5")
                        .font(.caption.bold())
                        .frame(width: 36, height: 36)
                        .background(.blue.opacity(0.15), in: Circle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)
                .accessibilityLabel("Decrease goal by 5")

                Button {
                    if dailyPageGoal > 1 { dailyPageGoal -= 1 }
                } label: {
                    Text("-1")
                        .font(.caption.bold())
                        .frame(width: 36, height: 36)
                        .background(.blue.opacity(0.1), in: Circle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)
                .accessibilityLabel("Decrease goal by 1")

                Text("\(dailyPageGoal)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .frame(width: 80)
                    .accessibilityLabel("\(dailyPageGoal) pages per day")

                Button {
                    dailyPageGoal += 1
                } label: {
                    Text("+1")
                        .font(.caption.bold())
                        .frame(width: 36, height: 36)
                        .background(.blue.opacity(0.1), in: Circle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)
                .accessibilityLabel("Increase goal by 1")

                Button {
                    dailyPageGoal += 5
                } label: {
                    Text("+5")
                        .font(.caption.bold())
                        .frame(width: 36, height: 36)
                        .background(.blue.opacity(0.15), in: Circle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.blue)
                .accessibilityLabel("Increase goal by 5")
            }

            Text("pages per day")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
