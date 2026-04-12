#if os(iOS)
import ActivityKit
import SwiftUI

// MARK: - Live Activity Manager

@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()
    private var currentActivity: Activity<ReadingActivityAttributes>?

    private init() {}

    func startActivity(book: Book) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

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

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil),
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
        let content = ActivityContent(state: state, staleDate: nil)
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
}
#endif
