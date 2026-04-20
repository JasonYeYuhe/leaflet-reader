import XCTest
@testable import GGCReader

final class BookLookupErrorTests: XCTestCase {

    // MARK: - LookupError.errorDescription

    func testInvalidISBNErrorDescriptionNonNil() {
        XCTAssertNotNil(BookLookupService.LookupError.invalidISBN.errorDescription)
    }

    func testNotFoundErrorDescriptionNonNil() {
        XCTAssertNotNil(BookLookupService.LookupError.notFound.errorDescription)
    }

    func testNetworkErrorDescriptionNonNil() {
        XCTAssertNotNil(BookLookupService.LookupError.networkError.errorDescription)
    }

    func testAllErrorDescriptionsDiffer() {
        let descriptions = [
            BookLookupService.LookupError.invalidISBN.errorDescription,
            BookLookupService.LookupError.notFound.errorDescription,
            BookLookupService.LookupError.networkError.errorDescription
        ]
        let unique = Set(descriptions.compactMap { $0 })
        XCTAssertEqual(unique.count, 3)
    }

    func testInvalidISBNErrorDescriptionNonEmpty() {
        XCTAssertFalse(BookLookupService.LookupError.invalidISBN.errorDescription?.isEmpty ?? true)
    }

    func testNotFoundErrorDescriptionNonEmpty() {
        XCTAssertFalse(BookLookupService.LookupError.notFound.errorDescription?.isEmpty ?? true)
    }

    func testNetworkErrorDescriptionNonEmpty() {
        XCTAssertFalse(BookLookupService.LookupError.networkError.errorDescription?.isEmpty ?? true)
    }
}
