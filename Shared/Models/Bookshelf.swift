import SwiftData
import Foundation

@Model
final class Bookshelf {
    var id: UUID = UUID()
    var name: String = ""
    var icon: String = "books.vertical"
    var colorName: String = "blue"
    var dateCreated: Date = Date()
    var sortOrder: Int = 0

    @Relationship(inverse: \Book.shelves)
    var books: [Book] = []

    init(name: String, icon: String = "books.vertical", colorName: String = "blue") {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.colorName = colorName
        self.dateCreated = Date()
    }
}
