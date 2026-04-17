import XCTest
@testable import GGCReader

final class TaskMetadataTests: XCTestCase {

    func testEncodedFormat() {
        let id = UUID(uuidString: "12345678-1234-1234-1234-123456789012")!
        let meta = TaskMetadata(bookID: id, pages: 42)
        XCTAssertEqual(meta.encoded, "leaflet:12345678-1234-1234-1234-123456789012:42")
    }

    func testParseRoundtrip() {
        let id = UUID()
        let original = TaskMetadata(bookID: id, pages: 100)
        let parsed = TaskMetadata.parse(from: original.encoded)
        XCTAssertNotNil(parsed)
        XCTAssertEqual(parsed?.bookID, id)
        XCTAssertEqual(parsed?.pages, 100)
    }

    func testParseNilInput() {
        XCTAssertNil(TaskMetadata.parse(from: nil))
    }

    func testParseInvalidInput() {
        XCTAssertNil(TaskMetadata.parse(from: "not a valid metadata string"))
    }

    func testParseMissingLeafletPrefix() {
        XCTAssertNil(TaskMetadata.parse(from: "12345678-1234-1234-1234-123456789012:42"))
    }
}
