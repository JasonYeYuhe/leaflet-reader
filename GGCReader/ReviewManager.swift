import StoreKit
#if os(iOS)
import UIKit
#endif

@MainActor
enum ReviewManager {
    private static let finishedBooksKey = "reviewManager.finishedBooksCount"
    private static let lastPromptedVersionKey = "reviewManager.lastPromptedVersion"
    private static let streakPromptedKey = "reviewManager.streakPrompted"
    private static let highestStreakHandledKey = "reviewManager.highestStreakHandled"

    /// Call when a book is marked as finished. Requests review after the 3rd finished book.
    static func recordBookFinished() {
        let count = UserDefaults.standard.integer(forKey: finishedBooksKey) + 1
        UserDefaults.standard.set(count, forKey: finishedBooksKey)

        if count == 3 {
            requestReviewIfEligible()
        }
    }

    /// Call when user achieves a streak milestone (7+ days).
    /// Only triggers once per milestone threshold (7, 30, 100, 365).
    static func recordStreakIfNewMilestone(_ currentStreak: Int) {
        let milestones = [7, 30, 100, 365]
        let highestHandled = UserDefaults.standard.integer(forKey: highestStreakHandledKey)

        guard let milestone = milestones.first(where: { currentStreak >= $0 && $0 > highestHandled }) else { return }
        UserDefaults.standard.set(milestone, forKey: highestStreakHandledKey)
        requestReviewIfEligible()
    }

    private static func requestReviewIfEligible() {
        let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        let lastPrompted = UserDefaults.standard.string(forKey: lastPromptedVersionKey) ?? ""

        guard currentVersion != lastPrompted else { return }

        #if os(iOS)
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else { return }

        // Only persist after confirming we can actually show the prompt
        UserDefaults.standard.set(currentVersion, forKey: lastPromptedVersionKey)
        AppStore.requestReview(in: scene)
        #endif
    }
}
