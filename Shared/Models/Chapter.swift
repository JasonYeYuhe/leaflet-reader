import SwiftData
import Foundation

@Model
final class Chapter {
    var id: UUID = UUID()
    var name: String = ""
    var startPage: Int = 0
    var endPage: Int = 0
    var sortOrder: Int = 0
    var book: Book?

    func contains(page: Int) -> Bool {
        page >= startPage && page <= endPage
    }

    var pageCount: Int {
        max(endPage - startPage + 1, 0)
    }

    init(name: String, startPage: Int, endPage: Int, sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.startPage = startPage
        self.endPage = endPage
        self.sortOrder = sortOrder
    }
}
