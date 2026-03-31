import SwiftData
import Foundation

@Model
final class ReadingLog {
    var id: UUID = UUID()
    var date: Date = Date()
    var fromPage: Int = 0
    var toPage: Int = 0
    var pagesRead: Int = 0
    var book: Book?

    init(fromPage: Int, toPage: Int) {
        self.id = UUID()
        self.date = Date()
        self.fromPage = fromPage
        self.toPage = toPage
        self.pagesRead = max(toPage - fromPage, 0)
    }
}
