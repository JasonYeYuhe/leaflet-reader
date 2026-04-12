import WidgetKit
import SwiftUI

#if os(iOS)
import ActivityKit

struct ReadingActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ReadingActivityAttributes.self) { context in
            // Lock Screen / Banner view
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "book.fill")
                        .font(.title2)
                        .foregroundStyle(colorFor(context.attributes.colorName))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing) {
                        Text(formatTime(context.state.elapsedSeconds))
                            .font(.title3.bold().monospacedDigit())
                        Text("reading")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text(context.attributes.bookTitle)
                            .font(.headline)
                            .lineLimit(1)
                        let pagesRead = context.state.currentPage - context.state.startPage
                        if pagesRead > 0 {
                            Text("+\(pagesRead) pages")
                                .font(.caption)
                                .foregroundStyle(.green)
                        }
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    let progress = Double(context.state.currentPage) / max(Double(context.attributes.totalPages), 1)
                    ProgressView(value: progress)
                        .tint(colorFor(context.attributes.colorName))
                }
            } compactLeading: {
                Image(systemName: "book.fill")
                    .foregroundStyle(colorFor(context.attributes.colorName))
            } compactTrailing: {
                Text(formatTimeCompact(context.state.elapsedSeconds))
                    .font(.caption.bold().monospacedDigit())
            } minimal: {
                Image(systemName: "book.fill")
                    .foregroundStyle(colorFor(context.attributes.colorName))
            }
        }
    }

    private func lockScreenView(context: ActivityViewContext<ReadingActivityAttributes>) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(colorFor(context.attributes.colorName).gradient)
                    .frame(width: 44, height: 62)
                Image(systemName: "book.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.bookTitle)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                Text(context.attributes.bookAuthor)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(spacing: 12) {
                    Label(formatTime(context.state.elapsedSeconds), systemImage: "timer")
                        .font(.caption.bold().monospacedDigit())
                    let pagesRead = context.state.currentPage - context.state.startPage
                    if pagesRead > 0 {
                        Label("+\(pagesRead) pages", systemImage: "book")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            }

            Spacer()

            ZStack {
                Circle()
                    .stroke(.quaternary, lineWidth: 4)
                let progress = Double(context.state.currentPage) / max(Double(context.attributes.totalPages), 1)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(colorFor(context.attributes.colorName), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(Int(progress * 100))%")
                    .font(.caption2.bold())
            }
            .frame(width: 44, height: 44)
        }
        .padding()
    }

    private func formatTime(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 { return String(format: "%d:%02d:%02d", h, m, s) }
        return String(format: "%02d:%02d", m, s)
    }

    private func formatTimeCompact(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
#endif
