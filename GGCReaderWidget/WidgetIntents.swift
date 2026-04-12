import AppIntents
import WidgetKit
import SwiftData

struct QuickLogPagesIntent: AppIntent {
    static let title: LocalizedStringResource = "Quick Log Pages"
    static let description: IntentDescription = "Log pages from widget"
    static let openAppWhenRun: Bool = false

    @Parameter(title: "Pages", default: 10)
    var pages: Int

    @MainActor
    func perform() async throws -> some IntentResult {
        let container = try SharedModelContainer.create()
        let context = container.mainContext

        // Find the most recently read book
        let descriptor = FetchDescriptor<Book>(sortBy: [SortDescriptor(\.lastReadDate, order: .reverse)])
        guard let book = try context.fetch(descriptor).first(where: { !$0.isFinished }) else {
            return .result()
        }

        let oldPage = book.currentPage
        let newPage = min(oldPage + pages, book.totalPages)
        guard newPage > oldPage else { return .result() }

        let log = ReadingLog(fromPage: oldPage, toPage: newPage)
        log.book = book
        context.insert(log)

        book.currentPage = newPage
        book.lastReadDate = Date()

        if book.isFinished {
            book.dateFinished = Date()
        }

        try context.save()

        // Update widget data from the modified store
        let allBooks = (try? context.fetch(FetchDescriptor<Book>())) ?? []
        let allLogs = (try? context.fetch(FetchDescriptor<ReadingLog>())) ?? []
        WidgetDataUpdater.update(books: allBooks, allLogs: allLogs)

        return .result()
    }
}

struct QuickLog10Intent: AppIntent {
    static let title: LocalizedStringResource = "+10 Pages"
    static let description: IntentDescription = "Log 10 pages"
    static let openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult {
        var intent = QuickLogPagesIntent()
        intent.pages = 10
        return try await intent.perform()
    }
}

struct QuickLog20Intent: AppIntent {
    static let title: LocalizedStringResource = "+20 Pages"
    static let description: IntentDescription = "Log 20 pages"
    static let openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult {
        var intent = QuickLogPagesIntent()
        intent.pages = 20
        return try await intent.perform()
    }
}
