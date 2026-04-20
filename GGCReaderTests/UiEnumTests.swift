import XCTest
@testable import GGCReader

// MARK: - BookSortOption

final class BookSortOptionTests: XCTestCase {

    func testAllCasesCount() {
        XCTAssertEqual(BookSortOption.allCases.count, 4)
    }

    func testLastReadRawValue() {
        XCTAssertEqual(BookSortOption.lastRead.rawValue, "Last Read")
    }

    func testTitleRawValue() {
        XCTAssertEqual(BookSortOption.title.rawValue, "Title")
    }

    func testDateAddedRawValue() {
        XCTAssertEqual(BookSortOption.dateAdded.rawValue, "Date Added")
    }

    func testProgressRawValue() {
        XCTAssertEqual(BookSortOption.progress.rawValue, "Progress")
    }

    func testAllRawValuesAreDistinct() {
        let values = BookSortOption.allCases.map(\.rawValue)
        XCTAssertEqual(Set(values).count, values.count)
    }

    func testAllRawValuesAreNonEmpty() {
        for option in BookSortOption.allCases {
            XCTAssertFalse(option.rawValue.isEmpty, "rawValue should not be empty for \(option)")
        }
    }
}

// MARK: - BookFilterOption

final class BookFilterOptionTests: XCTestCase {

    func testAllCasesCount() {
        XCTAssertEqual(BookFilterOption.allCases.count, 3)
    }

    func testAllRawValue() {
        XCTAssertEqual(BookFilterOption.all.rawValue, "All")
    }

    func testReadingRawValue() {
        XCTAssertEqual(BookFilterOption.reading.rawValue, "Reading")
    }

    func testFinishedRawValue() {
        XCTAssertEqual(BookFilterOption.finished.rawValue, "Finished")
    }

    func testAllRawValuesAreDistinct() {
        let values = BookFilterOption.allCases.map(\.rawValue)
        XCTAssertEqual(Set(values).count, values.count)
    }
}

// MARK: - SidebarItem (macOS only)

#if os(macOS)
final class SidebarItemTests: XCTestCase {

    func testAllCasesCount() {
        XCTAssertEqual(SidebarItem.allCases.count, 5)
    }

    func testBooksRawValue() {
        XCTAssertEqual(SidebarItem.books.rawValue, "Books")
    }

    func testGoalsRawValue() {
        XCTAssertEqual(SidebarItem.goals.rawValue, "Goals")
    }

    func testStatsRawValue() {
        XCTAssertEqual(SidebarItem.stats.rawValue, "Stats")
    }

    func testQuotesRawValue() {
        XCTAssertEqual(SidebarItem.quotes.rawValue, "Quotes")
    }

    func testSettingsRawValue() {
        XCTAssertEqual(SidebarItem.settings.rawValue, "Settings")
    }

    func testIDEqualsRawValue() {
        for item in SidebarItem.allCases {
            XCTAssertEqual(item.id, item.rawValue, "id mismatch for \(item)")
        }
    }

    func testAllIconsAreNonEmpty() {
        for item in SidebarItem.allCases {
            XCTAssertFalse(item.icon.isEmpty, "icon should not be empty for \(item)")
        }
    }

    func testAllIconsAreDistinct() {
        let icons = SidebarItem.allCases.map(\.icon)
        XCTAssertEqual(Set(icons).count, icons.count)
    }

    func testBooksIcon() {
        XCTAssertEqual(SidebarItem.books.icon, "books.vertical")
    }

    func testGoalsIcon() {
        XCTAssertEqual(SidebarItem.goals.icon, "flame")
    }

    func testStatsIcon() {
        XCTAssertEqual(SidebarItem.stats.icon, "chart.bar")
    }

    func testQuotesIcon() {
        XCTAssertEqual(SidebarItem.quotes.icon, "text.quote")
    }

    func testSettingsIcon() {
        XCTAssertEqual(SidebarItem.settings.icon, "gearshape")
    }
}
#endif

// MARK: - CardTheme

final class CardThemeTests: XCTestCase {

    func testAllCasesCount() {
        XCTAssertEqual(CardTheme.allCases.count, 4)
    }

    func testStandardRawValue() {
        XCTAssertEqual(CardTheme.standard.rawValue, "standard")
    }

    func testDarkRawValue() {
        XCTAssertEqual(CardTheme.dark.rawValue, "dark")
    }

    func testMinimalRawValue() {
        XCTAssertEqual(CardTheme.minimal.rawValue, "minimal")
    }

    func testGradientRawValue() {
        XCTAssertEqual(CardTheme.gradient.rawValue, "gradient")
    }

    func testIDEqualsRawValue() {
        for theme in CardTheme.allCases {
            XCTAssertEqual(theme.id, theme.rawValue, "id mismatch for \(theme)")
        }
    }

    func testStandardDisplayName() {
        XCTAssertEqual(CardTheme.standard.displayName, "Standard")
    }

    func testDarkDisplayName() {
        XCTAssertEqual(CardTheme.dark.displayName, "Dark")
    }

    func testMinimalDisplayName() {
        XCTAssertEqual(CardTheme.minimal.displayName, "Minimal")
    }

    func testGradientDisplayName() {
        XCTAssertEqual(CardTheme.gradient.displayName, "Gradient")
    }

    func testAllDisplayNamesAreDistinct() {
        let names = CardTheme.allCases.map(\.displayName)
        XCTAssertEqual(Set(names).count, names.count)
    }

    func testAllDisplayNamesAreNonEmpty() {
        for theme in CardTheme.allCases {
            XCTAssertFalse(theme.displayName.isEmpty, "displayName should not be empty for \(theme)")
        }
    }
}
