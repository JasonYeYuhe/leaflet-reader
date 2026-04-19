import XCTest
@testable import GGCReader

@MainActor
final class StoreManagerTests: XCTestCase {

    // MARK: - StoreError.errorDescription

    func testFailedVerificationErrorDescriptionNonNil() {
        XCTAssertNotNil(StoreError.failedVerification.errorDescription)
    }

    func testFailedVerificationErrorDescriptionNonEmpty() {
        XCTAssertFalse(StoreError.failedVerification.errorDescription!.isEmpty)
    }

    // MARK: - Free tier limits

    func testFreeBookLimitIs5() {
        XCTAssertEqual(StoreManager.freeBookLimit, 5)
    }

    func testFreeNoteLimitIs3() {
        XCTAssertEqual(StoreManager.freeNoteLimit, 3)
    }

    func testFreeBadgeLimitIs10() {
        XCTAssertEqual(StoreManager.freeBadgeLimit, 10)
    }

    // MARK: - Product IDs

    func testProductIDsAreDistinct() {
        let ids: Set<String> = [StoreManager.monthlyID, StoreManager.yearlyID, StoreManager.lifetimeID]
        XCTAssertEqual(ids.count, 3)
    }

    func testAllProductIDsNonEmpty() {
        XCTAssertFalse(StoreManager.monthlyID.isEmpty)
        XCTAssertFalse(StoreManager.yearlyID.isEmpty)
        XCTAssertFalse(StoreManager.lifetimeID.isEmpty)
    }

    // MARK: - BookLookupResult

    func testBookLookupResultStoredFields() {
        let result = BookLookupResult(title: "Dune", author: "Frank Herbert", totalPages: 604,
                                     coverURL: nil, publisher: "Chilton Books", isbn: "9780441013593")
        XCTAssertEqual(result.title, "Dune")
        XCTAssertEqual(result.author, "Frank Herbert")
        XCTAssertEqual(result.totalPages, 604)
        XCTAssertNil(result.coverURL)
        XCTAssertEqual(result.publisher, "Chilton Books")
        XCTAssertEqual(result.isbn, "9780441013593")
    }

    func testBookLookupResultWithCoverURL() {
        let url = URL(string: "https://covers.openlibrary.org/b/id/12345-M.jpg")!
        let result = BookLookupResult(title: "Foundation", author: "Asimov", totalPages: 244,
                                     coverURL: url, publisher: "Gnome Press", isbn: "9780553293357")
        XCTAssertEqual(result.coverURL, url)
    }
}
