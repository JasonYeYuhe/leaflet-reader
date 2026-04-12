import SwiftUI
import SwiftData

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Query private var books: [Book]

    var body: some View {
        if hasCompletedOnboarding || !books.isEmpty {
            ContentView()
                .onAppear {
                    // Migrate existing users — skip onboarding if they already have data
                    if !books.isEmpty && !hasCompletedOnboarding {
                        hasCompletedOnboarding = true
                    }
                }
        } else {
            OnboardingView()
        }
    }
}
