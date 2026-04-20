import XCTest
@testable import GGCReader

final class BookLookupServiceTests: XCTestCase {

    // MARK: - ISBN validation (throws before any network call)

    func testEmptyISBNThrowsInvalidISBN() async {
        do {
            _ = try await BookLookupService.shared.lookup(isbn: "")
            XCTFail("Expected invalidISBN error")
        } catch BookLookupService.LookupError.invalidISBN {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testWhitespaceOnlyISBNThrowsInvalidISBN() async {
        do {
            _ = try await BookLookupService.shared.lookup(isbn: "   ")
            XCTFail("Expected invalidISBN error")
        } catch BookLookupService.LookupError.invalidISBN {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testDashesOnlyISBNThrowsInvalidISBN() async {
        do {
            _ = try await BookLookupService.shared.lookup(isbn: "---")
            XCTFail("Expected invalidISBN error")
        } catch BookLookupService.LookupError.invalidISBN {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
