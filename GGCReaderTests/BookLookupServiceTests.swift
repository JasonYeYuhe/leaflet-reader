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

    func testLettersOnlyISBNThrowsInvalidISBN() async {
        do {
            _ = try await BookLookupService.shared.lookup(isbn: "ABCDEF")
            XCTFail("Expected invalidISBN error")
        } catch BookLookupService.LookupError.invalidISBN {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testMixedAlphanumericISBNThrowsInvalidISBN() async {
        // "978-ABC-123" cleans to "978ABC123" — not a valid ISBN character set
        do {
            _ = try await BookLookupService.shared.lookup(isbn: "978-ABC-123")
            XCTFail("Expected invalidISBN error")
        } catch BookLookupService.LookupError.invalidISBN {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testXOnlyISBNThrowsInvalidISBN() async {
        // "X" alone has an empty numeric prefix — should fail validation
        do {
            _ = try await BookLookupService.shared.lookup(isbn: "X")
            XCTFail("Expected invalidISBN error")
        } catch BookLookupService.LookupError.invalidISBN {
            // expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
