import XCTest
@testable import Chess98

final class StreakCalculatorTests: XCTestCase {
    // Anchor date: 2026-05-25 12:00 UTC. Use a fixed calendar so tests
    // don't drift with the host time zone or weekday convention.
    private let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        c.firstWeekday = 2  // Monday
        return c
    }()

    private func day(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        var c = DateComponents()
        c.year = year; c.month = month; c.day = day
        c.hour = hour; c.minute = 0
        c.timeZone = calendar.timeZone
        return calendar.date(from: c)!
    }

    // MARK: evaluateLaunch

    func testLaunchNoChangeWhenNoPriorPlay() {
        let result = StreakCalculator.evaluateLaunch(
            lastPlayedDay: nil,
            freezesAvailable: 1,
            today: day(2026, 5, 25),
            calendar: calendar
        )
        XCTAssertEqual(result, .noChange)
    }

    func testLaunchNoChangeWhenPlayedToday() {
        let result = StreakCalculator.evaluateLaunch(
            lastPlayedDay: day(2026, 5, 25, hour: 3),
            freezesAvailable: 0,
            today: day(2026, 5, 25, hour: 22),
            calendar: calendar
        )
        XCTAssertEqual(result, .noChange)
    }

    func testLaunchNoChangeWhenPlayedYesterday() {
        let result = StreakCalculator.evaluateLaunch(
            lastPlayedDay: day(2026, 5, 24),
            freezesAvailable: 0,
            today: day(2026, 5, 25),
            calendar: calendar
        )
        XCTAssertEqual(result, .noChange)
    }

    func testLaunchFreezeAppliedWhenTwoDaysAgoAndFreezeAvailable() {
        let result = StreakCalculator.evaluateLaunch(
            lastPlayedDay: day(2026, 5, 23),
            freezesAvailable: 1,
            today: day(2026, 5, 25),
            calendar: calendar
        )
        let missed = calendar.startOfDay(for: day(2026, 5, 24))
        XCTAssertEqual(result, .freezeApplied(missedDay: missed))
    }

    func testLaunchBrokenWhenTwoDaysAgoAndNoFreeze() {
        let result = StreakCalculator.evaluateLaunch(
            lastPlayedDay: day(2026, 5, 23),
            freezesAvailable: 0,
            today: day(2026, 5, 25),
            calendar: calendar
        )
        XCTAssertEqual(result, .broken)
    }

    func testLaunchBrokenWhenThreeOrMoreDaysAgoEvenWithFreeze() {
        let result = StreakCalculator.evaluateLaunch(
            lastPlayedDay: day(2026, 5, 20),
            freezesAvailable: 1,
            today: day(2026, 5, 25),
            calendar: calendar
        )
        XCTAssertEqual(result, .broken)
    }

    // MARK: evaluateCompletion

    func testCompletionNewStreakWhenNoPriorPlay() {
        let result = StreakCalculator.evaluateCompletion(
            lastPlayedDay: nil,
            today: day(2026, 5, 25),
            calendar: calendar
        )
        XCTAssertEqual(result, .newStreak)
    }

    func testCompletionSameDayWhenAlreadyPlayedToday() {
        let result = StreakCalculator.evaluateCompletion(
            lastPlayedDay: day(2026, 5, 25, hour: 8),
            today: day(2026, 5, 25, hour: 23),
            calendar: calendar
        )
        XCTAssertEqual(result, .sameDay)
    }

    func testCompletionContinuingWhenPlayedYesterday() {
        let result = StreakCalculator.evaluateCompletion(
            lastPlayedDay: day(2026, 5, 24),
            today: day(2026, 5, 25),
            calendar: calendar
        )
        XCTAssertEqual(result, .continuing)
    }

    func testCompletionNewStreakWhenGapLongerThanOneDay() {
        let result = StreakCalculator.evaluateCompletion(
            lastPlayedDay: day(2026, 5, 22),
            today: day(2026, 5, 25),
            calendar: calendar
        )
        XCTAssertEqual(result, .newStreak)
    }

    // MARK: startOfWeek

    func testStartOfWeekReturnsMondayStartOfDay() {
        // May 25 2026 is a Monday. Start of week should be midnight that day.
        let monday = StreakCalculator.startOfWeek(
            containing: day(2026, 5, 25, hour: 22),
            calendar: calendar
        )
        XCTAssertEqual(monday, calendar.startOfDay(for: day(2026, 5, 25)))
    }

    func testStartOfWeekFromMidWeek() {
        // May 27 2026 (Wednesday) → start of week is May 25 Monday.
        let monday = StreakCalculator.startOfWeek(
            containing: day(2026, 5, 27),
            calendar: calendar
        )
        XCTAssertEqual(monday, calendar.startOfDay(for: day(2026, 5, 25)))
    }
}
