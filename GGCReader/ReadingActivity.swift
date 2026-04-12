#if os(iOS)
import ActivityKit
import SwiftUI

// MARK: - Live Activity Manager

@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()
    private var currentActivity: Activity<ReadingActivityAttributes>?

    private init() {
        // Rehydrate: pick up any existing activity from a prior launch
        currentActivity = Activity<ReadingActivityAttributes>.activities.first
    }

    func startActivity(book: Book) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        // End any existing activity first to prevent overlaps
        endAllExisting()

        let attributes = ReadingActivityAttributes(
            bookTitle: book.title,
            bookAuthor: book.author,
            totalPages: book.totalPages,
            colorName: book.coverColorName
        )

        let state = ReadingActivityAttributes.ContentState(
            elapsedSeconds: 0,
            currentPage: book.currentPage,
            startPage: book.currentPage
        )

        // Stale after 4 hours (user probably forgot to stop)
        let staleDate = Date().addingTimeInterval(4 * 3600)

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: staleDate),
                pushType: nil
            )
            currentActivity = activity
        } catch {
            print("[LiveActivity] Failed to start: \(error)")
        }
    }

    func updateActivity(elapsedSeconds: Int, currentPage: Int, startPage: Int) {
        guard let activity = currentActivity else { return }
        let state = ReadingActivityAttributes.ContentState(
            elapsedSeconds: elapsedSeconds,
            currentPage: currentPage,
            startPage: startPage
        )
        let staleDate = Date().addingTimeInterval(4 * 3600)
        let content = ActivityContent(state: state, staleDate: staleDate)
        nonisolated(unsafe) let act = activity
        Task.detached {
            await act.update(content)
        }
    }

    func endActivity(currentPage: Int, startPage: Int, elapsedSeconds: Int) {
        guard let activity = currentActivity else { return }
        let finalState = ReadingActivityAttributes.ContentState(
            elapsedSeconds: elapsedSeconds,
            currentPage: currentPage,
            startPage: startPage
        )
        let content = ActivityContent(state: finalState, staleDate: nil)
        currentActivity = nil
        nonisolated(unsafe) let act = activity
        Task.detached {
            await act.end(content, dismissalPolicy: .after(.now + 60))
        }
    }

    private func endAllExisting() {
        for activity in Activity<ReadingActivityAttributes>.activities {
            nonisolated(unsafe) let act = activity
            Task.detached {
                await act.end(nil, dismissalPolicy: .immediate)
            }
        }
        currentActivity = nil
    }
}
#endif
