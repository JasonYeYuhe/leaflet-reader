import SwiftUI

struct CelebrationView: View {
    @Binding var isShowing: Bool
    let emoji: String
    let message: LocalizedStringKey

    @State private var particles: [Particle] = []
    @State private var opacity: Double = 1
    @State private var viewSize: CGSize = CGSize(width: 400, height: 800)

    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        let emoji: String
        let size: CGFloat
        let rotation: Double
    }

    private let emojis = ["🎉", "⭐️", "🔥", "📖", "✨", "🏆"]

    var body: some View {
        if isShowing {
            GeometryReader { geo in
                ZStack {
                    // Particles
                    ForEach(particles) { p in
                        Text(p.emoji)
                            .font(.system(size: p.size))
                            .rotationEffect(.degrees(p.rotation))
                            .position(x: p.x, y: p.y)
                    }

                    // Center message
                    VStack(spacing: 12) {
                        Text(emoji)
                            .font(.system(size: 60))
                        Text(message)
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)
                    }
                    .padding(32)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
                    .shadow(radius: 20)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                }
                .onAppear {
                    viewSize = geo.size
                    animate()
                }
            }
            .opacity(opacity)
            .allowsHitTesting(true)
            .onTapGesture { dismiss() }
        }
    }

    private func animate() {
        let w = viewSize.width
        let h = viewSize.height

        // Generate particles
        particles = (0..<20).map { _ in
            Particle(
                x: CGFloat.random(in: 0...w),
                y: h + 50,
                emoji: emojis.randomElement() ?? "🎉",
                size: CGFloat.random(in: 16...32),
                rotation: Double.random(in: -180...180)
            )
        }

        // Animate particles upward
        withAnimation(.easeOut(duration: 1.5)) {
            for i in particles.indices {
                particles[i].y = CGFloat.random(in: 50...h * 0.6)
                particles[i].x += CGFloat.random(in: -60...60)
            }
        }

        // Auto-dismiss after 2.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            dismiss()
        }
    }

    private func dismiss() {
        withAnimation(.easeOut(duration: 0.3)) {
            opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            isShowing = false
            opacity = 1
        }
    }
}
