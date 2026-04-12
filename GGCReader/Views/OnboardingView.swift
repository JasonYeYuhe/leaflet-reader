import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    @State private var showingAddBook = false

    private let pages: [(icon: String, title: LocalizedStringKey, subtitle: LocalizedStringKey, color: Color)] = [
        ("books.vertical.fill", "Track Your Reading", "Log pages, set goals, and build your personal library", .blue),
        ("flame.fill", "Build Streaks & Habits", "Daily goals, reading streaks, and achievement badges keep you motivated", .orange),
        ("chart.bar.fill", "Discover Insights", "See your reading stats, monthly trends, and year-in-review reports", .purple),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(pages.indices, id: \.self) { index in
                    onboardingPage(pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            // Bottom action area
            VStack(spacing: 16) {
                if currentPage == pages.count - 1 {
                    Button {
                        hasCompletedOnboarding = true
                        showingAddBook = true
                    } label: {
                        Text("Get Started")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        hasCompletedOnboarding = true
                    } label: {
                        Text("Skip for Now")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Button {
                        withAnimation { currentPage += 1 }
                    } label: {
                        Text("Next")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        hasCompletedOnboarding = true
                    } label: {
                        Text("Skip")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
        .sheet(isPresented: $showingAddBook) {
            BookFormView()
        }
    }

    private func onboardingPage(_ page: (icon: String, title: LocalizedStringKey, subtitle: LocalizedStringKey, color: Color)) -> some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(page.color.opacity(0.12))
                    .frame(width: 120, height: 120)
                Image(systemName: page.icon)
                    .font(.system(size: 48))
                    .foregroundStyle(page.color)
            }

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
    }
}
