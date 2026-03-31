import SwiftData
import Foundation

@Model
final class BookNote {
    var id: UUID = UUID()
    var content: String = ""
    var page: Int = 0
    var dateCreated: Date = Date()
    var book: Book?

    init(content: String, page: Int = 0) {
        self.id = UUID()
        self.content = content
        self.page = page
        self.dateCreated = Date()
    }
}
