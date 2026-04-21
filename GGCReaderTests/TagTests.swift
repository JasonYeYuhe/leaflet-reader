import XCTest
@testable import GGCReader

final class TagTests: XCTestCase {

    // MARK: - init defaults

    func testDefaultColor() {
        let tag = Tag(name: "Fiction")
        XCTAssertEqual(tag.color, .blue)
    }

    func testDefaultColorName() {
        let tag = Tag(name: "Fiction")
        XCTAssertEqual(tag.colorName, "blue")
    }

    func testInitWithColor() {
        let tag = Tag(name: "Sci-Fi", color: .red)
        XCTAssertEqual(tag.color, .red)
        XCTAssertEqual(tag.colorName, "red")
    }

    func testInitWithExpandedColor() {
        let tag = Tag(name: "Mystery", color: .coral)
        XCTAssertEqual(tag.color, .coral)
        XCTAssertEqual(tag.colorName, "coral")
    }

    // MARK: - color getter

    func testColorGetterReadsColorName() {
        let tag = Tag(name: "Test")
        tag.colorName = "green"
        XCTAssertEqual(tag.color, .green)
    }

    func testColorGetterFallsBackToBlueForInvalidName() {
        let tag = Tag(name: "Test")
        tag.colorName = "notacolor"
        XCTAssertEqual(tag.color, .blue)
    }

    func testColorGetterFallsBackToBlueForEmptyName() {
        let tag = Tag(name: "Test")
        tag.colorName = ""
        XCTAssertEqual(tag.color, .blue)
    }

    // MARK: - color setter

    func testColorSetterUpdatesColorName() {
        let tag = Tag(name: "Test")
        tag.color = .purple
        XCTAssertEqual(tag.colorName, "purple")
    }

    func testColorSetterRoundtrip() {
        let tag = Tag(name: "Test")
        for color in CoverColor.allCases {
            tag.color = color
            XCTAssertEqual(tag.colorName, color.rawValue, "colorName mismatch after setting \(color)")
            XCTAssertEqual(tag.color, color, "color getter mismatch after setting \(color)")
        }
    }

    // MARK: - id + name

    func testIDIsAssigned() {
        let tag = Tag(name: "Classics")
        XCTAssertNotNil(tag.id)
    }

    func testTwoInstancesHaveDifferentIDs() {
        let a = Tag(name: "Fiction")
        let b = Tag(name: "Non-Fiction")
        XCTAssertNotEqual(a.id, b.id)
    }

    func testNameStoredInInit() {
        let tag = Tag(name: "Science Fiction")
        XCTAssertEqual(tag.name, "Science Fiction")
    }
}
