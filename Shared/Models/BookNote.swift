import SwiftData
import Foundation

enum NoteType: String, Codable, CaseIterable {
    case thought = "thought"
    case quote = "quote"

    var displayName: String {
        switch self {
        case .thought: String(localized: "Thought")
        case .quote: String(localized: "Quote")
        }
    }

    var icon: String {
        switch self {
        case .thought: "bubble.left"
        case .quote: "text.quote"
        }
    }
}

@Model
final class BookNote {
    var id: UUID = UUID()
    var content: String = ""
    var page: Int = 0
    var dateCreated: Date = Date()
    var noteTypeRaw: String = NoteType.thought.rawValue
    var isFavorite: Bool = false
    var book: Book?

    var noteType: NoteType {
        get { NoteType(rawValue: noteTypeRaw) ?? .thought }
        set { noteTypeRaw = newValue.rawValue }
    }

    init(content: String, page: Int = 0, noteType: NoteType = .thought) {
        self.id = UUID()
        self.content = content
        self.page = page
        self.noteTypeRaw = noteType.rawValue
        self.dateCreated = Date()
    }
}
