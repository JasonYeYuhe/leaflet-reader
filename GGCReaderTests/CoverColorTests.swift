import XCTest
@testable import GGCReader

final class CoverColorTests: XCTestCase {

    // MARK: - allCases

    func testAllCasesCount() {
        XCTAssertEqual(CoverColor.allCases.count, 25)
    }

    func testAllCasesContainsOriginalColors() {
        let original: Set<CoverColor> = [.red, .blue, .green, .orange, .purple, .brown, .teal, .indigo, .pink, .mint]
        for color in original {
            XCTAssertTrue(CoverColor.allCases.contains(color), "Missing original color: \(color)")
        }
    }

    func testAllCasesContainsExpandedColors() {
        let expanded: Set<CoverColor> = [.coral, .crimson, .navy, .sky, .forest, .lime, .gold, .amber, .violet, .lavender, .slate, .charcoal, .peach, .rose, .cyan]
        for color in expanded {
            XCTAssertTrue(CoverColor.allCases.contains(color), "Missing expanded color: \(color)")
        }
    }

    // MARK: - rawValue roundtrip

    func testRawValueRoundtripBlue() {
        XCTAssertEqual(CoverColor(rawValue: "blue"), .blue)
    }

    func testRawValueRoundtripRed() {
        XCTAssertEqual(CoverColor(rawValue: "red"), .red)
    }

    func testRawValueRoundtripCoral() {
        XCTAssertEqual(CoverColor(rawValue: "coral"), .coral)
    }

    func testRawValueRoundtripCharcoal() {
        XCTAssertEqual(CoverColor(rawValue: "charcoal"), .charcoal)
    }

    func testRawValueRoundtripAllCases() {
        for color in CoverColor.allCases {
            XCTAssertEqual(CoverColor(rawValue: color.rawValue), color, "Roundtrip failed for \(color.rawValue)")
        }
    }

    func testInvalidRawValueReturnsNil() {
        XCTAssertNil(CoverColor(rawValue: "unknown"))
        XCTAssertNil(CoverColor(rawValue: ""))
        XCTAssertNil(CoverColor(rawValue: "Blue"))
    }

    // MARK: - displayName

    func testDisplayNameIsCapitalized() {
        XCTAssertEqual(CoverColor.blue.displayName, "Blue")
        XCTAssertEqual(CoverColor.red.displayName, "Red")
        XCTAssertEqual(CoverColor.coral.displayName, "Coral")
        XCTAssertEqual(CoverColor.lavender.displayName, "Lavender")
        XCTAssertEqual(CoverColor.charcoal.displayName, "Charcoal")
    }

    func testDisplayNameMatchesRawValueCapitalized() {
        for color in CoverColor.allCases {
            XCTAssertEqual(color.displayName, color.rawValue.capitalized)
        }
    }
}
