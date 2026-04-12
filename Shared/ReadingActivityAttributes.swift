#if os(iOS)
import ActivityKit

struct ReadingActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var elapsedSeconds: Int
        var currentPage: Int
        var startPage: Int
    }

    let bookTitle: String
    let bookAuthor: String
    let totalPages: Int
    let colorName: String
}
#endif
