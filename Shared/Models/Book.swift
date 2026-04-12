import SwiftData
import Foundation

enum BookType: String, Codable, CaseIterable {
    case physical = "physical"
    case ebook = "ebook"
    case audiobook = "audiobook"

    var displayName: String {
        switch self {
        case .physical: String(localized: "Physical Book")
        case .ebook: String(localized: "E-book")
        case .audiobook: String(localized: "Audiobook")
        }
    }

    var icon: String {
        switch self {
        case .physical: "book.closed"
        case .ebook: "ipad"
        case .audiobook: "headphones"
        }
    }

    /// What the "total" field represents
    var totalLabel: String {
        switch self {
        case .physical, .ebook: String(localized: "Total Pages")
        case .audiobook: String(localized: "Total Minutes")
        }
    }

    /// What the "current" field represents
    var currentLabel: String {
        switch self {
        case .physical, .ebook: String(localized: "Current Page")
        case .audiobook: String(localized: "Minutes Listened")
        }
    }

    var unitName: String {
        switch self {
        case .physical, .ebook: String(localized: "pages")
        case .audiobook: String(localized: "min")
        }
    }
}

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
    var rating: Int?
    var review: String?
    var dateFinished: Date?
    var bookTypeRaw: String = BookType.physical.rawValue
    var shelves: [Bookshelf] = []
    @Attribute(.externalStorage) var coverImageData: Data?

    var bookType: BookType {
        get { BookType(rawValue: bookTypeRaw) ?? .physical }
        set { bookTypeRaw = newValue.rawValue }
    }

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

    /// Formatted progress string based on book type
    var formattedProgress: String {
        switch bookType {
        case .audiobook:
            let hours = currentPage / 60
            let mins = currentPage % 60
            if hours > 0 {
                return "\(hours)h \(mins)m"
            }
            return "\(mins)m"
        case .physical, .ebook:
            return "\(currentPage)/\(totalPages)"
        }
    }

    /// Formatted remaining string
    var formattedRemaining: String {
        switch bookType {
        case .audiobook:
            let rem = pagesRemaining
            let hours = rem / 60
            let mins = rem % 60
            if hours > 0 {
                return "\(hours)h \(mins)m left"
            }
            return "\(mins)m left"
        case .physical, .ebook:
            return "\(pagesRemaining) pages left"
        }
    }

    init(title: String, author: String, totalPages: Int, coverColor: CoverColor = .blue, bookType: BookType = .physical) {
        self.id = UUID()
        self.title = title
        self.author = author
        self.totalPages = totalPages
        self.coverColorName = coverColor.rawValue
        self.bookTypeRaw = bookType.rawValue
        self.dateAdded = Date()
    }
}
