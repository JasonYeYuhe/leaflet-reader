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

    // MARK: - dateAdded field

    func testParsesDateAddedSlashFormat() throws {
        let csv = makeCSV(header: fullHeader, rows: ["Dune,Frank Herbert,,604,,2022/01/10,to-read,"])
        let books = try GoodreadsImporter.parse(csv: csv)
        XCTAssertNotNil(books[0].dateAdded)
        let components = Calendar.current.dateComponents([.year, .month, .day], from: books[0].dateAdded!)
        XCTAssertEqual(components.year, 2022)
        XCTAssertEqual(components.month, 1)
        XCTAssertEqual(components.day, 10)
    }

    func testParsesDateAddedDashFormat() throws {
        let csv = makeCSV(header: fullHeader, rows: ["Dune,Frank Herbert,,604,,2022-03-25,to-read,"])
        let books = try GoodreadsImporter.parse(csv: csv)
        XCTAssertNotNil(books[0].dateAdded)
        let components = Calendar.current.dateComponents([.year, .month, .day], from: books[0].dateAdded!)
        XCTAssertEqual(components.year, 2022)
        XCTAssertEqual(components.month, 3)
        XCTAssertEqual(components.day, 25)
    }

    // MARK: - Pages edge cases

    func testParsesNonNumericPagesDefaultsToZero() throws {
        let csv = makeCSV(header: fullHeader, rows: ["Dune,Frank Herbert,,N/A,,,read,"])
        let books = try GoodreadsImporter.parse(csv: csv)
        XCTAssertEqual(books[0].pages, 0)
    }

    func testParsesEmptyPagesDefaultsToZero() throws {
        let csv = makeCSV(header: fullHeader, rows: ["Dune,Frank Herbert,,,,,,"])
        let books = try GoodreadsImporter.parse(csv: csv)
        XCTAssertEqual(books[0].pages, 0)
    }

    // MARK: - Date parsing edge cases

    func testDateReadWithUnsupportedFormatIsNil() throws {
        // "15 June 2023" is a natural language format — not matched by yyyy/MM/dd or yyyy-MM-dd
        let csv = makeCSV(header: fullHeader, rows: ["Dune,Frank Herbert,,604,15 June 2023,,read,"])
        let books = try GoodreadsImporter.parse(csv: csv)
        XCTAssertNil(books[0].dateRead)
    }

    // MARK: - ISBN edge cases

    func testStripsEmptyExcelISBNToEmptyString() throws {
        // Goodreads exports an empty ISBN as ="" which becomes = after CSV parsing
        // The = is then stripped, yielding ""
        let csv = makeCSV(header: fullHeader, rows: ["Dune,Frank Herbert,=\"\",,,,read,"])
        let books = try GoodreadsImporter.parse(csv: csv)
        XCTAssertEqual(books[0].isbn, "")
    }

    // MARK: - Row length edge cases

    func testSkipsWhitespaceTitleRow() throws {
        let csv = makeCSV(header: "Title,Author", rows: ["   ,Frank Herbert", "Dune,Frank Herbert"])
        let books = try GoodreadsImporter.parse(csv: csv)
        XCTAssertEqual(books.count, 1)
        XCTAssertEqual(books[0].title, "Dune")
    }

    func testHandlesRowShorterThanHeader() throws {
        // Row has fewer fields than expected — should not crash, short rows are skipped or parsed with defaults
        let csv = makeCSV(header: fullHeader, rows: ["Dune", "Foundation,Isaac Asimov"])
        let books = try GoodreadsImporter.parse(csv: csv)
        // "Dune" alone (1 field) is shorter than header (8 fields, titleIdx=0, authorIdx=1)
        // row.count <= max(0, 1) so it is skipped; Foundation row has no author at idx=1 → author=""
        XCTAssertEqual(books.count, 1)
        XCTAssertEqual(books[0].title, "Foundation")
    }

    // MARK: - ImportError descriptions

    func testInvalidFormatErrorDescriptionNonNil() {
        XCTAssertNotNil(GoodreadsImporter.ImportError.invalidFormat.errorDescription)
    }

    func testNoBooksErrorDescriptionNonNil() {
        XCTAssertNotNil(GoodreadsImporter.ImportError.noBooks.errorDescription)
    }

    func testErrorDescriptionsDiffer() {
        XCTAssertNotEqual(
            GoodreadsImporter.ImportError.invalidFormat.errorDescription,
            GoodreadsImporter.ImportError.noBooks.errorDescription
        )
    }

    // MARK: - Shelf defaults

    func testToReadShelfDefaultValues() throws {
        let csv = makeCSV(header: fullHeader, rows: ["Dune,Frank Herbert,,604,,2022/01/10,to-read,"])
        let books = try GoodreadsImporter.parse(csv: csv)
        XCTAssertEqual(books[0].shelf, "to-read")
        XCTAssertNil(books[0].dateRead)
    }

    func testParsesCurrentlyReadingShelf() throws {
        let csv = makeCSV(header: fullHeader, rows: ["Dune,Frank Herbert,,604,,,currently-reading,"])
        let books = try GoodreadsImporter.parse(csv: csv)
        XCTAssertEqual(books[0].shelf, "currently-reading")
    }

    // MARK: - ISBN column fallback

    func testParsesISBNFallbackColumnWhenISBN13Absent() throws {
        // Goodreads older exports use "ISBN" not "ISBN13"; parser uses ?? fallback
        let altHeader = "Title,Author,ISBN,Number of Pages,Date Read,Date Added,Exclusive Shelf,Publisher"
        let csv = makeCSV(header: altHeader, rows: ["Dune,Frank Herbert,9780441013593,604,,,read,"])
        let books = try GoodreadsImporter.parse(csv: csv)
        XCTAssertEqual(books[0].isbn, "9780441013593")
    }

    func testISBNEmptyWhenNeitherColumnPresent() throws {
        let noISBNHeader = "Title,Author,Number of Pages,Date Read,Date Added,Exclusive Shelf,Publisher"
        let csv = makeCSV(header: noISBNHeader, rows: ["Dune,Frank Herbert,604,,,read,"])
        let books = try GoodreadsImporter.parse(csv: csv)
        XCTAssertEqual(books[0].isbn, "")
    }
}
