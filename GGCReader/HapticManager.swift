#if os(iOS)
import UIKit

@MainActor
enum HapticManager {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func taskDone() {
        impact(.medium)
    }

    static func goalAchieved() {
        notification(.success)
    }

    static func bookFinished() {
        notification(.success)
    }

    static func tap() {
        impact(.light)
    }
}
#else
@MainActor
enum HapticManager {
    static func impact(_ style: Any? = nil) {}
    static func notification(_ type: Any? = nil) {}
    static func selection() {}
    static func taskDone() {}
    static func goalAchieved() {}
    static func bookFinished() {}
    static func tap() {}
}
#endif
