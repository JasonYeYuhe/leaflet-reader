import XCTest
@testable import GGCReader

final class BookNoteTests: XCTestCase {

    // MARK: - NoteType.icon

    func testThoughtIcon() {
        XCTAssertEqual(NoteType.thought.icon, "bubble.left")
    }

    func testQuoteIcon() {
        XCTAssertEqual(NoteType.quote.icon, "text.quote")
    }

    // MARK: - NoteType.allCases

    func testNoteTypeAllCasesCount() {
        XCTAssertEqual(NoteType.allCases.count, 2)
    }

    func testNoteTypeAllCasesContainsThought() {
        XCTAssertTrue(NoteType.allCases.contains(.thought))
    }

    func testNoteTypeAllCasesContainsQuote() {
        XCTAssertTrue(NoteType.allCases.contains(.quote))
    }

    // MARK: - NoteType rawValue

    func testThoughtRawValue() {
        XCTAssertEqual(NoteType.thought.rawValue, "thought")
    }

    func testQuoteRawValue() {
        XCTAssertEqual(NoteType.quote.rawValue, "quote")
    }

    // MARK: - BookNote.noteType computed property

    func testNoteTypeGetterDefaultsToThought() {
        let note = BookNote(content: "Test")
        XCTAssertEqual(note.noteType, .thought)
    }

    func testNoteTypeGetterForQuote() {
        let note = BookNote(content: "Test", noteType: .quote)
        XCTAssertEqual(note.noteType, .quote)
    }

    func testNoteTypeSetterUpdatesRawValue() {
        let note = BookNote(content: "Test")
        note.noteType = .quote
        XCTAssertEqual(note.noteTypeRaw, "quote")
    }

    func testNoteTypeInvalidRawValueFallsBackToThought() {
        let note = BookNote(content: "Test")
        note.noteTypeRaw = "unknown_type"
        XCTAssertEqual(note.noteType, .thought)
    }

    // MARK: - BookNote init

    func testContentStoredCorrectly() {
        let note = BookNote(content: "My favorite quote")
        XCTAssertEqual(note.content, "My favorite quote")
    }

    func testPageDefaultsToZero() {
        let note = BookNote(content: "Test")
        XCTAssertEqual(note.page, 0)
    }

    func testPageStoredCorrectly() {
        let note = BookNote(content: "Test", page: 42)
        XCTAssertEqual(note.page, 42)
    }

    func testIsFavoriteDefaultsFalse() {
        let note = BookNote(content: "Test")
        XCTAssertFalse(note.isFavorite)
    }
}
