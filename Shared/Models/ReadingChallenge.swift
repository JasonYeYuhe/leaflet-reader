import SwiftData
import Foundation

enum ChallengeType: String, Codable, CaseIterable {
    case booksCount = "booksCount"
    case pagesCount = "pagesCount"
    case streakDays = "streakDays"
    case readingDays = "readingDays"

    var displayName: String {
        switch self {
        case .booksCount: String(localized: "Books to Finish")
        case .pagesCount: String(localized: "Pages to Read")
        case .streakDays: String(localized: "Day Streak")
        case .readingDays: String(localized: "Reading Days")
        }
    }

    var icon: String {
        switch self {
        case .booksCount: "book.closed.fill"
        case .pagesCount: "doc.text.fill"
        case .streakDays: "flame.fill"
        case .readingDays: "calendar"
        }
    }

    var unitName: String {
        switch self {
        case .booksCount: String(localized: "books")
        case .pagesCount: String(localized: "pages")
        case .streakDays: String(localized: "days")
        case .readingDays: String(localized: "days")
        }
    }
}

@Model
final class ReadingChallenge {
    var id: UUID = UUID()
    var title: String = ""
    var challengeTypeRaw: String = ChallengeType.booksCount.rawValue
    var targetValue: Int = 0
    var startDate: Date = Date()
    var endDate: Date = Date()
    var isCompleted: Bool = false
    var dateCompleted: Date?
    var colorName: String = "blue"

    var challengeType: ChallengeType {
        get { ChallengeType(rawValue: challengeTypeRaw) ?? .booksCount }
        set { challengeTypeRaw = newValue.rawValue }
    }

    var isActive: Bool {
        !isCompleted && endDate >= Date()
    }

    var isExpired: Bool {
        !isCompleted && endDate < Date()
    }

    var daysRemaining: Int {
        max(Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0, 0)
    }

    var color: CoverColor {
        CoverColor(rawValue: colorName) ?? .blue
    }

    init(title: String, type: ChallengeType, target: Int, endDate: Date, color: CoverColor = .blue) {
        self.id = UUID()
        self.title = title
        self.challengeTypeRaw = type.rawValue
        self.targetValue = target
        self.startDate = Date()
        self.endDate = endDate
        self.colorName = color.rawValue
    }
}
