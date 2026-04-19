import XCTest
@testable import GGCReader

final class AppIconOptionTests: XCTestCase {

    // MARK: - allCases

    func testAllCasesCount() {
        XCTAssertEqual(AppIconOption.allCases.count, 6)
    }

    // MARK: - rawValue

    func testBlueRawValue() {
        XCTAssertEqual(AppIconOption.blue.rawValue, "AppIcon")
    }

    func testGreenRawValue() {
        XCTAssertEqual(AppIconOption.green.rawValue, "AppIconGreen")
    }

    func testPurpleRawValue() {
        XCTAssertEqual(AppIconOption.purple.rawValue, "AppIconPurple")
    }

    func testOrangeRawValue() {
        XCTAssertEqual(AppIconOption.orange.rawValue, "AppIconOrange")
    }

    func testTealRawValue() {
        XCTAssertEqual(AppIconOption.teal.rawValue, "AppIconTeal")
    }

    func testDarkRawValue() {
        XCTAssertEqual(AppIconOption.dark.rawValue, "AppIconDark")
    }

    // MARK: - iconName (nil for default blue, rawValue for others)

    func testBlueIconNameIsNil() {
        XCTAssertNil(AppIconOption.blue.iconName)
    }

    func testNonBlueIconNamesEqualRawValue() {
        for option in AppIconOption.allCases where option != .blue {
            XCTAssertEqual(option.iconName, option.rawValue, "iconName mismatch for \(option)")
        }
    }

    func testNonBlueIconNameCount() {
        let withIconName = AppIconOption.allCases.filter { $0.iconName != nil }
        XCTAssertEqual(withIconName.count, 5)
    }

    // MARK: - id

    func testIDEqualsRawValue() {
        for option in AppIconOption.allCases {
            XCTAssertEqual(option.id, option.rawValue, "id mismatch for \(option)")
        }
    }
}
