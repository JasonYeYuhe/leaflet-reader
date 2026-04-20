import XCTest
import SwiftUI
@testable import GGCReader

final class ColorHelpersTests: XCTestCase {

    // MARK: - Named colors

    func testColorForRed() {
        XCTAssertEqual(colorFor("red"), Color.red)
    }

    func testColorForOrange() {
        XCTAssertEqual(colorFor("orange"), Color.orange)
    }

    func testColorForYellow() {
        XCTAssertEqual(colorFor("yellow"), Color.yellow)
    }

    func testColorForGreen() {
        XCTAssertEqual(colorFor("green"), Color.green)
    }

    func testColorForMint() {
        XCTAssertEqual(colorFor("mint"), Color.mint)
    }

    func testColorForTeal() {
        XCTAssertEqual(colorFor("teal"), Color.teal)
    }

    func testColorForCyan() {
        XCTAssertEqual(colorFor("cyan"), Color.cyan)
    }

    func testColorForBlue() {
        XCTAssertEqual(colorFor("blue"), Color.blue)
    }

    func testColorForIndigo() {
        XCTAssertEqual(colorFor("indigo"), Color.indigo)
    }

    func testColorForPurple() {
        XCTAssertEqual(colorFor("purple"), Color.purple)
    }

    func testColorForPink() {
        XCTAssertEqual(colorFor("pink"), Color.pink)
    }

    func testColorForBrown() {
        XCTAssertEqual(colorFor("brown"), Color.brown)
    }

    // MARK: - Default fallback

    func testUnknownNameDefaultsToBlue() {
        XCTAssertEqual(colorFor("coral"), Color.blue)
    }

    func testEmptyStringDefaultsToBlue() {
        XCTAssertEqual(colorFor(""), Color.blue)
    }

    func testNumericStringDefaultsToBlue() {
        XCTAssertEqual(colorFor("123"), Color.blue)
    }

    // MARK: - Case sensitivity

    func testUppercaseRedDefaultsToBlue() {
        XCTAssertEqual(colorFor("Red"), Color.blue)
    }

    func testAllCapsBlueDefaultsToBlue() {
        XCTAssertEqual(colorFor("BLUE"), Color.blue)
    }

    func testMixedCaseGreenDefaultsToBlue() {
        XCTAssertEqual(colorFor("Green"), Color.blue)
    }
}
