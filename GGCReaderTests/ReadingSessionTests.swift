import XCTest
@testable import GGCReader

final class ReadingSessionTests: XCTestCase {

    // MARK: - formattedDuration helpers

    private func session(seconds: Int) -> ReadingSession {
        let s = ReadingSession(startPage: 0)
        s.durationSeconds = seconds
        return s
    }

    // MARK: - formattedDuration

    func testFormattedDurationZero() {
        XCTAssertEqual(session(seconds: 0).formattedDuration, "0m 00s")
    }

    func testFormattedDurationSecondsOnly() {
        XCTAssertEqual(session(seconds: 45).formattedDuration, "0m 45s")
    }

    func testFormattedDurationMinutesAndSeconds() {
        XCTAssertEqual(session(seconds: 90).formattedDuration, "1m 30s")
    }

    func testFormattedDurationMinutesZeroSeconds() {
        XCTAssertEqual(session(seconds: 300).formattedDuration, "5m 00s")
    }

    func testFormattedDurationExactlyOneHour() {
        XCTAssertEqual(session(seconds: 3600).formattedDuration, "1h 00m")
    }

    func testFormattedDurationHoursAndMinutes() {
        XCTAssertEqual(session(seconds: 5400).formattedDuration, "1h 30m")
    }

    func testFormattedDurationMultipleHours() {
        XCTAssertEqual(session(seconds: 7200).formattedDuration, "2h 00m")
    }

    func testFormattedDurationHoursDropsSeconds() {
        // When hours > 0, seconds are not displayed — only hours and minutes
        XCTAssertEqual(session(seconds: 3661).formattedDuration, "1h 01m")
    }

    // MARK: - isActive

    func testIsActiveWhenEndTimeIsNil() {
        let s = ReadingSession(startPage: 0)
        XCTAssertTrue(s.isActive)
    }

    func testIsActiveWhenEndTimeSet() {
        let s = ReadingSession(startPage: 0)
        s.endTime = Date()
        XCTAssertFalse(s.isActive)
    }

    // MARK: - init stored fields

    func testStartPageStoredAtInit() {
        let s = ReadingSession(startPage: 42)
        XCTAssertEqual(s.startPage, 42)
    }

    func testEndPageDefaultsToZero() {
        let s = ReadingSession(startPage: 10)
        XCTAssertEqual(s.endPage, 0)
    }

    // MARK: - stop(endPage:)

    func testStopSetsEndPage() {
        let s = ReadingSession(startPage: 10)
        s.stop(endPage: 75)
        XCTAssertEqual(s.endPage, 75)
    }

    func testStopSetsEndTime() {
        let s = ReadingSession(startPage: 0)
        XCTAssertNil(s.endTime)
        s.stop(endPage: 50)
        XCTAssertNotNil(s.endTime)
    }

    func testStopMakesSessionInactive() {
        let s = ReadingSession(startPage: 0)
        s.stop(endPage: 50)
        XCTAssertFalse(s.isActive)
    }

    func testStopCalculatesDurationFromStartTime() {
        let s = ReadingSession(startPage: 0)
        s.startTime = Date(timeIntervalSinceNow: -90)
        s.stop(endPage: 100)
        XCTAssertGreaterThanOrEqual(s.durationSeconds, 89)
        XCTAssertLessThanOrEqual(s.durationSeconds, 95)
    }
}
