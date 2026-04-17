import XCTest
@testable import GGCReader

final class GoodreadsImporterTests: XCTestCase {

    // MARK: - Helpers

    private func makeCSV(header: String, rows: [String]) -> String {
        ([header] + rows).joined(separator: "\n")
    }

    private let fullHeader = "Title,Author,ISBN13,Number of Pages,Date Read,Date Added,Exclusive Shelf,Publisher"

    // MARK: - Error cases

    func testThrowsInvalidFormatOnSingleLine() {
        XCTAssertThrowsError(try GoodreadsImporter.parse(csv: "Title,Author")) { error in
            XCTAssertEqual((error as? GoodreadsImporter.ImportError), .invalidFormat)
        }
    }

    func testThrowsInvalidFormatWhenMissingTitleColumn() {
        let csv = makeCSV(header: "Author,Pages", rows: ["Tolkien,1200"])
        XCTAssertThrowsError(try GoodreadsImporter.parse(csv: csv)) { error in
            XCTAssertEqual((error as? GoodreadsImporter.ImportError), .invalidFormat)
        }
    }

    func testThrowsInvalidFormatWhenMissingAuthorColumn() {
        let csv = makeCSV(header: "Title,Pages", rows: ["Dune,604"])
        XCTAssertThrowsError(try GoodreadsImporter.parse(csv: csv)) { error in
            XCTAssertEqual((error as? GoodreadsImporter.ImportError), .invalidFormat)
        }
    }

    func testThrowsNoBooksWhenAllTitlesEmpty() {
        let csv = makeCSV(header: fullHeader, rows: [",Tolkien,,,,,,"])
        XCTAssertThrowsError(try GoodreadsImporter.parse(csv: csv)) { error in
            XCTAssertEqual((error as? GoodreadsImporter.ImportError), .noBooks)
        }
    }

    // MARK: - Basic parsing

    func testParsesMinimalCSV() throws {
        let csv = makeCSV(header: "Title,Author", rows: ["Dune,Frank Herbert"])
        let books = try GoodreadsImporter.parse(csv: csv)
        XCTAssertEqual(books.count, 1)
        XCTAssertEqual(books[0].title, "Dune")
        XCTAssertEqual(books[0].author, "Frank Herbert")
    }

    func testParsesMultipleRows() throws {
        let csv = makeCSV(header: "Title,Author", rows: [
            "Dune,Frank Herbert",
            "Foundation,Isaac Asimov",
            "Neuromancer,William Gibson"
        ])
        let books = try GoodreadsImporter.parse(csv: csv)
        XCTAssertEqual(books.count, 3)
    }

    func testSkipsRowsWithEmptyTitle() throws {
        let csv = makeCSV(header: "Title,Author", rows: [
            "Dune,Frank Herbert",
            ",Unknown Author",
            "Foundation,Isaac Asimov"
        ])
        let books = try GoodreadsImporter.parse(csv: csv)
        XCTAssertEqual(books.count, 2)
        XCTAssertEqual(books[0].title, "Dune")
        XCTAssertEqual(books[1].title, "Foundation")
    }

    // MARK: - Field parsing

    func testParsesPageCount() throws {
        let csv = makeCSV(header: fullHeader, rows: ["Dune,Frank Herbert,,604,,,read,"])
        let books = try GoodreadsImporter.parse(csv: csv)
        XCTAssertEqual(books[0].pages, 604)
    }

    func testParsesShelf() throws {
        let csv = makeCSV(header: fullHeader, rows: ["Dune,Frank Herbert,,,,,,"])
        let books = try GoodreadsImporter.parse(csv: csv)
        XCTAssertEqual(books[0].shelf, "")
    }

    func testParsesShelfRead() throws {
        let csv = makeCSV(header: fullHeader, rows: ["Dune,Frank Herbert,,604,,, read ,"])
        let books = try GoodreadsImporter.parse(csv: csv)
        XCTAssertEqual(books[0].shelf, "read")
    }

    func testParsesPublisher() throws {
        let csv = makeCSV(header: fullHeader, rows: ["Dune,Frank Herbert,,604,,,read,Chilton Books"])
        let books = try GoodreadsImporter.parse(csv: csv)
        XCTAssertEqual(books[0].publisher, "Chilton Books")
    }

    // MARK: - ISBN stripping

    func testStripsISBNGoodreadsFormat() throws {
        let csv = makeCSV(header: fullHeader, rows: ["Dune,Frank Herbert,=\"9780441013593\",,,,read,"])
        let books = try GoodreadsImporter.parse(csv: csv)
        XCTAssertEqual(books[0].isbn, "9780441013593")
    }

    func testStripsISBNPlainFormat() throws {
        let csv = makeCSV(header: fullHeader, rows: ["Dune,Frank Herbert,9780441013593,,,,read,"])
        let books = try GoodreadsImporter.parse(csv: csv)
        XCTAssertEqual(books[0].isbn, "9780441013593")
    }

    // MARK: - Date parsing

    func testParsesDateReadSlashFormat() throws {
        let csv = makeCSV(header: fullHeader, rows: ["Dune,Frank Herbert,,604,2023/06/15,,read,"])
        let books = try GoodreadsImporter.parse(csv: csv)
        XCTAssertNotNil(books[0].dateRead)
        let components = Calendar.current.dateComponents([.year, .month, .day], from: books[0].dateRead!)
        XCTAssertEqual(components.year, 2023)
        XCTAssertEqual(components.month, 6)
        XCTAssertEqual(components.day, 15)
    }

    func testParsesDateReadDashFormat() throws {
        let csv = makeCSV(header: fullHeader, rows: ["Dune,Frank Herbert,,604,2023-06-15,,read,"])
        let books = try GoodreadsImporter.parse(csv: csv)
        XCTAssertNotNil(books[0].dateRead)
        let components = Calendar.current.dateComponents([.year, .month, .day], from: books[0].dateRead!)
        XCTAssertEqual(components.year, 2023)
        XCTAssertEqual(components.month, 6)
        XCTAssertEqual(components.day, 15)
    }

    func testNilDateReadWhenBlank() throws {
        let csv = makeCSV(header: fullHeader, rows: ["Dune,Frank Herbert,,604,,,read,"])
        let books = try GoodreadsImporter.parse(csv: csv)
        XCTAssertNil(books[0].dateRead)
    }

    // MARK: - CSV quoting

    func testParsesQuotedTitleWithComma() throws {
        let csv = makeCSV(header: "Title,Author", rows: ["\"Dune, the Novel\",Frank Herbert"])
        let books = try GoodreadsImporter.parse(csv: csv)
        XCTAssertEqual(books.count, 1)
        XCTAssertEqual(books[0].title, "Dune, the Novel")
    }

    func testIgnoresBlankLinesInCSV() throws {
        let csv = "Title,Author\nDune,Frank Herbert\n\n\nFoundation,Isaac Asimov\n"
        let books = try GoodreadsImporter.parse(csv: csv)
        XCTAssertEqual(books.count, 2)
    }
}
