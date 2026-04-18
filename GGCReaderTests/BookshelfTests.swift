import XCTest
@testable import GGCReader

final class BookshelfTests: XCTestCase {

    // MARK: - init: name

    func testNameStoredCorrectly() {
        let shelf = Bookshelf(name: "Favorites")
        XCTAssertEqual(shelf.name, "Favorites")
    }

    func testEmptyNameAllowed() {
        let shelf = Bookshelf(name: "")
        XCTAssertEqual(shelf.name, "")
    }

    func testUnicodeName() {
        let shelf = Bookshelf(name: "拾叶书架")
        XCTAssertEqual(shelf.name, "拾叶书架")
    }

    // MARK: - init: icon

    func testDefaultIconIsBooksVertical() {
        let shelf = Bookshelf(name: "Test")
        XCTAssertEqual(shelf.icon, "books.vertical")
    }

    func testCustomIconStoredCorrectly() {
        let shelf = Bookshelf(name: "Test", icon: "star.fill")
        XCTAssertEqual(shelf.icon, "star.fill")
    }

    // MARK: - init: colorName

    func testDefaultColorNameIsBlue() {
        let shelf = Bookshelf(name: "Test")
        XCTAssertEqual(shelf.colorName, "blue")
    }

    func testCustomColorNameStoredCorrectly() {
        let shelf = Bookshelf(name: "Test", colorName: "red")
        XCTAssertEqual(shelf.colorName, "red")
    }

    // MARK: - init: sortOrder & dateCreated

    func testDefaultSortOrderIsZero() {
        let shelf = Bookshelf(name: "Test")
        XCTAssertEqual(shelf.sortOrder, 0)
    }

    func testDateCreatedIsRecent() {
        let before = Date()
        let shelf = Bookshelf(name: "Test")
        let after = Date()
        XCTAssertGreaterThanOrEqual(shelf.dateCreated, before)
        XCTAssertLessThanOrEqual(shelf.dateCreated, after)
    }

    // MARK: - UUID uniqueness

    func testIDIsAssigned() {
        let shelf = Bookshelf(name: "Test")
        XCTAssertNotNil(shelf.id)
    }

    func testTwoInstancesHaveDifferentIDs() {
        let a = Bookshelf(name: "A")
        let b = Bookshelf(name: "B")
        XCTAssertNotEqual(a.id, b.id)
    }

    // MARK: - mutations

    func testNameMutation() {
        let shelf = Bookshelf(name: "Old")
        shelf.name = "New"
        XCTAssertEqual(shelf.name, "New")
    }

    func testSortOrderMutation() {
        let shelf = Bookshelf(name: "Test")
        shelf.sortOrder = 5
        XCTAssertEqual(shelf.sortOrder, 5)
    }
}
