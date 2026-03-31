import SwiftUI

struct ProgressRingView: View {
    let progress: Double
    let color: Color
    var lineWidth: CGFloat = 10
    var size: CGFloat = 120

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: clampedProgress)
                .stroke(
                    color.gradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: clampedProgress)

            VStack(spacing: 2) {
                Text("\(Int(clampedProgress * 100))%")
                    .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
            }
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    HStack(spacing: 30) {
        ProgressRingView(progress: 0.35, color: .blue)
        ProgressRingView(progress: 0.78, color: .green, size: 80)
        ProgressRingView(progress: 1.0, color: .orange, size: 60)
    }
    .padding()
}
