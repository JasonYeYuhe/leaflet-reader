import XCTest
@testable import GGCReader

final class BookTypeTests: XCTestCase {

    // MARK: - allCases

    func testAllCasesCount() {
        XCTAssertEqual(BookType.allCases.count, 3)
    }

    func testAllCasesContainsPhysical() {
        XCTAssertTrue(BookType.allCases.contains(.physical))
    }

    func testAllCasesContainsEbook() {
        XCTAssertTrue(BookType.allCases.contains(.ebook))
    }

    func testAllCasesContainsAudiobook() {
        XCTAssertTrue(BookType.allCases.contains(.audiobook))
    }

    // MARK: - rawValue

    func testPhysicalRawValue() {
        XCTAssertEqual(BookType.physical.rawValue, "physical")
    }

    func testEbookRawValue() {
        XCTAssertEqual(BookType.ebook.rawValue, "ebook")
    }

    func testAudiobookRawValue() {
        XCTAssertEqual(BookType.audiobook.rawValue, "audiobook")
    }

    func testRawValueRoundtrip() {
        for type in BookType.allCases {
            XCTAssertEqual(BookType(rawValue: type.rawValue), type)
        }
    }

    func testInvalidRawValueReturnsNil() {
        XCTAssertNil(BookType(rawValue: "magazine"))
    }

    // MARK: - icon

    func testPhysicalIcon() {
        XCTAssertEqual(BookType.physical.icon, "book.closed")
    }

    func testEbookIcon() {
        XCTAssertEqual(BookType.ebook.icon, "ipad")
    }

    func testAudiobookIcon() {
        XCTAssertEqual(BookType.audiobook.icon, "headphones")
    }

    func testAllIconsNonEmpty() {
        for type in BookType.allCases {
            XCTAssertFalse(type.icon.isEmpty)
        }
    }

    // MARK: - totalLabel

    func testPhysicalTotalLabel() {
        XCTAssertEqual(BookType.physical.totalLabel, "Total Pages")
    }

    func testEbookTotalLabel() {
        XCTAssertEqual(BookType.ebook.totalLabel, "Total Pages")
    }

    func testAudiobookTotalLabel() {
        XCTAssertEqual(BookType.audiobook.totalLabel, "Total Minutes")
    }

    // MARK: - currentLabel

    func testPhysicalCurrentLabel() {
        XCTAssertEqual(BookType.physical.currentLabel, "Current Page")
    }

    func testEbookCurrentLabel() {
        XCTAssertEqual(BookType.ebook.currentLabel, "Current Page")
    }

    func testAudiobookCurrentLabel() {
        XCTAssertEqual(BookType.audiobook.currentLabel, "Minutes Listened")
    }

    // MARK: - unitName

    func testPhysicalUnitName() {
        XCTAssertEqual(BookType.physical.unitName, "pages")
    }

    func testEbookUnitName() {
        XCTAssertEqual(BookType.ebook.unitName, "pages")
    }

    func testAudiobookUnitName() {
        XCTAssertEqual(BookType.audiobook.unitName, "min")
    }

    func testAllUnitNamesNonEmpty() {
        for type in BookType.allCases {
            XCTAssertFalse(type.unitName.isEmpty)
        }
    }

    // MARK: - displayName

    func testPhysicalDisplayName() {
        XCTAssertEqual(BookType.physical.displayName, "Physical Book")
    }

    func testEbookDisplayName() {
        XCTAssertEqual(BookType.ebook.displayName, "E-book")
    }

    func testAudiobookDisplayName() {
        XCTAssertEqual(BookType.audiobook.displayName, "Audiobook")
    }

    func testAllDisplayNamesNonEmpty() {
        for type in BookType.allCases {
            XCTAssertFalse(type.displayName.isEmpty)
        }
    }

    // MARK: - physical and ebook share labels

    func testPhysicalAndEbookShareTotalLabel() {
        XCTAssertEqual(BookType.physical.totalLabel, BookType.ebook.totalLabel)
    }

    func testPhysicalAndEbookShareCurrentLabel() {
        XCTAssertEqual(BookType.physical.currentLabel, BookType.ebook.currentLabel)
    }

    func testPhysicalAndEbookShareUnitName() {
        XCTAssertEqual(BookType.physical.unitName, BookType.ebook.unitName)
    }

    func testAudiobookDifferentTotalLabelFromPhysical() {
        XCTAssertNotEqual(BookType.audiobook.totalLabel, BookType.physical.totalLabel)
    }
}
