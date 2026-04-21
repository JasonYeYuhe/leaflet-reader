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

    // MARK: - Expanded palette

    func testColorForCoral() {
        XCTAssertEqual(colorFor("coral"), CoverColor.coral.color)
    }

    func testColorForCrimson() {
        XCTAssertEqual(colorFor("crimson"), CoverColor.crimson.color)
    }

    func testColorForNavy() {
        XCTAssertEqual(colorFor("navy"), CoverColor.navy.color)
    }

    func testColorForSky() {
        XCTAssertEqual(colorFor("sky"), CoverColor.sky.color)
    }

    func testColorForForest() {
        XCTAssertEqual(colorFor("forest"), CoverColor.forest.color)
    }

    func testColorForLime() {
        XCTAssertEqual(colorFor("lime"), CoverColor.lime.color)
    }

    func testColorForGold() {
        XCTAssertEqual(colorFor("gold"), CoverColor.gold.color)
    }

    func testColorForAmber() {
        XCTAssertEqual(colorFor("amber"), CoverColor.amber.color)
    }

    func testColorForViolet() {
        XCTAssertEqual(colorFor("violet"), CoverColor.violet.color)
    }

    func testColorForLavender() {
        XCTAssertEqual(colorFor("lavender"), CoverColor.lavender.color)
    }

    func testColorForSlate() {
        XCTAssertEqual(colorFor("slate"), CoverColor.slate.color)
    }

    func testColorForCharcoal() {
        XCTAssertEqual(colorFor("charcoal"), CoverColor.charcoal.color)
    }

    func testColorForPeach() {
        XCTAssertEqual(colorFor("peach"), CoverColor.peach.color)
    }

    func testColorForRose() {
        XCTAssertEqual(colorFor("rose"), CoverColor.rose.color)
    }

    func testAllCoverColorsRoundtrip() {
        for color in CoverColor.allCases {
            XCTAssertEqual(colorFor(color.rawValue), color.color, "colorFor(\(color.rawValue)) returned wrong color")
        }
    }

    // MARK: - Default fallback

    func testUnknownNameDefaultsToBlue() {
        XCTAssertEqual(colorFor("unknown_color"), Color.blue)
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
