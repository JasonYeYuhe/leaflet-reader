import SwiftData
import Foundation

@Model
final class Book {
    var id: UUID = UUID()
    var title: String = ""
    var author: String = ""
    var totalPages: Int = 0
    var currentPage: Int = 0
    var coverColorName: String = "blue"
    var dateAdded: Date = Date()
    var lastReadDate: Date?

    @Relationship(deleteRule: .cascade, inverse: \Chapter.book)
    var chapters: [Chapter] = []

    @Relationship(deleteRule: .cascade, inverse: \ReadingLog.book)
    var readingLogs: [ReadingLog] = []

    @Relationship(deleteRule: .cascade, inverse: \BookNote.book)
    var notes: [BookNote] = []

    @Relationship(deleteRule: .cascade, inverse: \ReadingSession.book)
    var sessions: [ReadingSession] = []

    var isbn: String = ""
    var publisher: String = ""
    var genre: String = ""
    var shelves: [Bookshelf] = []
    @Attribute(.externalStorage) var coverImageData: Data?

    var progressPercentage: Double {
        guard totalPages > 0 else { return 0 }
        return min(Double(currentPage) / Double(totalPages), 1.0)
    }

    var pagesRemaining: Int {
        max(totalPages - currentPage, 0)
    }

    var isFinished: Bool {
        currentPage >= totalPages && totalPages > 0
    }

    var currentChapter: Chapter? {
        chapters
            .sorted { $0.startPage < $1.startPage }
            .last { $0.startPage <= currentPage }
    }

    var coverColor: CoverColor {
        get { CoverColor(rawValue: coverColorName) ?? .blue }
        set { coverColorName = newValue.rawValue }
    }

    init(title: String, author: String, totalPages: Int, coverColor: CoverColor = .blue) {
        self.id = UUID()
        self.title = title
        self.author = author
        self.totalPages = totalPages
        self.coverColorName = coverColor.rawValue
        self.dateAdded = Date()
    }
}
