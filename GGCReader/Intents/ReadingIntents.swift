import AppIntents
import SwiftData

// MARK: - Log Reading Progress Intent

struct LogReadingProgressIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Reading Progress"
    static let description: IntentDescription = "Record pages read for a book in æstel"
    static let openAppWhenRun: Bool = false

    @Parameter(title: "Book Title")
    var bookTitle: String

    @Parameter(title: "Pages Read", default: 10)
    var pagesRead: Int

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        guard pagesRead > 0 else {
            return .result(value: "Invalid input", dialog: "Pages read must be greater than zero.")
        }

        let container = try SharedModelContainer.create()
        let context = container.mainContext

        let title = bookTitle
        let descriptor = FetchDescriptor<Book>()
        let allBooks = try context.fetch(descriptor)

        guard let book = allBooks.first(where: {
            $0.title.localizedCaseInsensitiveContains(title)
        }) else {
            return .result(
                value: "Book not found",
                dialog: "I couldn't find a book matching \"\(bookTitle)\" in your library."
            )
        }

        let oldPage = book.currentPage
        let newPage = min(oldPage + pagesRead, book.totalPages)

        let log = ReadingLog(fromPage: oldPage, toPage: newPage)
        log.book = book
        context.insert(log)

        book.currentPage = newPage
        book.lastReadDate = Date()

        if book.isFinished && oldPage < book.totalPages {
            book.dateFinished = Date()
        }

        try context.save()

        let unit = book.bookType.unitName
        let progress = Int(book.progressPercentage * 100)
        return .result(
            value: "Logged \(pagesRead) \(unit) for \(book.title)",
            dialog: "Logged \(pagesRead) \(unit) for \"\(book.title)\". You're now at \(progress)%!"
        )
    }
}

// MARK: - Get Today's Reading Stats Intent

struct GetTodayStatsIntent: AppIntent {
    static let title: LocalizedStringResource = "Today's Reading Stats"
    static let description: IntentDescription = "Get your reading stats for today from æstel"
    static let openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let container = try SharedModelContainer.create()
        let context = container.mainContext

        let startOfDay = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<ReadingLog>(
            predicate: #Predicate<ReadingLog> { $0.date >= startOfDay }
        )
        let todayLogs = try context.fetch(descriptor)
        let todayPages = todayLogs.reduce(0) { $0 + $1.pagesRead }

        let booksDescriptor = FetchDescriptor<Book>()
        let allBooks = try context.fetch(booksDescriptor)
        let readingCount = allBooks.filter { !$0.isFinished && $0.currentPage > 0 }.count

        return .result(
            value: "Today: \(todayPages) pages read, \(readingCount) in progress",
            dialog: "You've read \(todayPages) pages today. You have \(readingCount) books in progress."
        )
    }
}

// MARK: - App Shortcuts Provider

struct AestelShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogReadingProgressIntent(),
            phrases: [
                "Log reading in \(.applicationName)",
                "Record pages in \(.applicationName)",
                "Update my reading in \(.applicationName)"
            ],
            shortTitle: "Log Reading",
            systemImageName: "book"
        )
        AppShortcut(
            intent: GetTodayStatsIntent(),
            phrases: [
                "Today's reading in \(.applicationName)",
                "Reading stats in \(.applicationName)",
                "How much did I read in \(.applicationName)"
            ],
            shortTitle: "Today's Reading",
            systemImageName: "chart.bar"
        )
    }
}
