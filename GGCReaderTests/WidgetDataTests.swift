import XCTest
@testable import GGCReader

final class WidgetDataTests: XCTestCase {

    // MARK: - WidgetBookData

    func testWidgetBookDataInit() {
        let book = WidgetBookData(title: "Dune", author: "Frank Herbert", currentPage: 100, totalPages: 412, colorName: "orange", progressPercentage: 0.24)
        XCTAssertEqual(book.title, "Dune")
        XCTAssertEqual(book.author, "Frank Herbert")
        XCTAssertEqual(book.currentPage, 100)
        XCTAssertEqual(book.totalPages, 412)
        XCTAssertEqual(book.colorName, "orange")
        XCTAssertEqual(book.progressPercentage, 0.24, accuracy: 0.001)
    }

    func testWidgetBookDataCodableRoundtrip() throws {
        let original = WidgetBookData(title: "1984", author: "Orwell", currentPage: 50, totalPages: 328, colorName: "red", progressPercentage: 0.15)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WidgetBookData.self, from: data)
        XCTAssertEqual(decoded.title, original.title)
        XCTAssertEqual(decoded.author, original.author)
        XCTAssertEqual(decoded.currentPage, original.currentPage)
        XCTAssertEqual(decoded.totalPages, original.totalPages)
        XCTAssertEqual(decoded.colorName, original.colorName)
        XCTAssertEqual(decoded.progressPercentage, original.progressPercentage, accuracy: 0.001)
    }

    // MARK: - WidgetData init

    func testWidgetDataInit() {
        let book = WidgetBookData(title: "Neuromancer", author: "Gibson", currentPage: 200, totalPages: 271, colorName: "teal", progressPercentage: 0.74)
        let widget = WidgetData(currentBook: book, todayPages: 30, dailyGoal: 20, currentStreak: 5, lastUpdated: Date())
        XCTAssertEqual(widget.todayPages, 30)
        XCTAssertEqual(widget.dailyGoal, 20)
        XCTAssertEqual(widget.currentStreak, 5)
        XCTAssertNotNil(widget.currentBook)
        XCTAssertEqual(widget.currentBook?.title, "Neuromancer")
    }

    func testWidgetDataNilBook() {
        let widget = WidgetData(currentBook: nil, todayPages: 0, dailyGoal: 20, currentStreak: 0, lastUpdated: Date())
        XCTAssertNil(widget.currentBook)
        XCTAssertEqual(widget.todayPages, 0)
        XCTAssertEqual(widget.currentStreak, 0)
    }

    func testWidgetDataCodableRoundtrip() throws {
        let book = WidgetBookData(title: "Shogun", author: "Clavell", currentPage: 300, totalPages: 1210, colorName: "brown", progressPercentage: 0.25)
        let original = WidgetData(currentBook: book, todayPages: 15, dailyGoal: 20, currentStreak: 3, lastUpdated: Date(timeIntervalSince1970: 1_700_000_000))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WidgetData.self, from: data)
        XCTAssertEqual(decoded.todayPages, original.todayPages)
        XCTAssertEqual(decoded.dailyGoal, original.dailyGoal)
        XCTAssertEqual(decoded.currentStreak, original.currentStreak)
        XCTAssertEqual(decoded.currentBook?.title, original.currentBook?.title)
        XCTAssertEqual(decoded.lastUpdated.timeIntervalSince1970, original.lastUpdated.timeIntervalSince1970, accuracy: 0.001)
    }

    func testWidgetDataNilBookCodableRoundtrip() throws {
        let original = WidgetData(currentBook: nil, todayPages: 0, dailyGoal: 30, currentStreak: 0, lastUpdated: Date(timeIntervalSince1970: 0))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WidgetData.self, from: data)
        XCTAssertNil(decoded.currentBook)
        XCTAssertEqual(decoded.todayPages, 0)
        XCTAssertEqual(decoded.dailyGoal, 30)
    }

    // MARK: - placeholder

    func testPlaceholderHasCurrentBook() {
        XCTAssertNotNil(WidgetData.placeholder.currentBook)
    }

    func testPlaceholderBookTitle() {
        XCTAssertFalse(WidgetData.placeholder.currentBook!.title.isEmpty)
    }

    func testPlaceholderProgressInRange() {
        let p = WidgetData.placeholder.currentBook!.progressPercentage
        XCTAssertGreaterThanOrEqual(p, 0.0)
        XCTAssertLessThanOrEqual(p, 1.0)
    }

    func testPlaceholderStreakPositive() {
        XCTAssertGreaterThan(WidgetData.placeholder.currentStreak, 0)
    }

    func testPlaceholderDailyGoalPositive() {
        XCTAssertGreaterThan(WidgetData.placeholder.dailyGoal, 0)
    }

    // MARK: - appGroupID

    func testAppGroupIDFormat() {
        XCTAssertTrue(WidgetData.appGroupID.hasPrefix("group."))
    }
}
