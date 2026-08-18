//
//  GameDayTests.swift
//  DraftTests
//

import XCTest
@testable import Draft

final class GameDayTests: XCTestCase {

    private let eastern = TimeZone(identifier: "America/New_York")!

    func testThursdaySundayMondayAreGameDays() {
        XCTAssertTrue(GameDay.isGameDay(date("2026-09-10 12:00"))) // Thursday
        XCTAssertTrue(GameDay.isGameDay(date("2026-09-13 13:00"))) // Sunday
        XCTAssertTrue(GameDay.isGameDay(date("2026-09-14 20:00"))) // Monday
        XCTAssertFalse(GameDay.isGameDay(date("2026-09-09 12:00"))) // Wednesday
        XCTAssertFalse(GameDay.isGameDay(date("2026-09-11 12:00"))) // Friday
    }

    func testVotesStayOpenBeforeSeason() {
        XCTAssertTrue(
            GameDay.canChangeMatchupVote(
                selectedWeek: 1,
                currentWeek: 0,
                scoringHasStarted: false,
                now: date("2026-08-17 12:00")
            )
        )
    }

    func testPastWeeksLock() {
        XCTAssertFalse(
            GameDay.canChangeMatchupVote(
                selectedWeek: 1,
                currentWeek: 2,
                scoringHasStarted: false,
                now: date("2026-09-16 12:00")
            )
        )
    }

    func testScoringLocksTheBoard() {
        XCTAssertFalse(
            GameDay.canChangeMatchupVote(
                selectedWeek: 1,
                currentWeek: 1,
                scoringHasStarted: true,
                now: date("2026-09-10 12:00")
            )
        )
    }

    func testCurrentWeekLocksAtThursdayKickoff() {
        XCTAssertTrue(
            GameDay.canChangeMatchupVote(
                selectedWeek: 1,
                currentWeek: 1,
                scoringHasStarted: false,
                now: date("2026-09-10 20:00")
            )
        )
        XCTAssertFalse(
            GameDay.canChangeMatchupVote(
                selectedWeek: 1,
                currentWeek: 1,
                scoringHasStarted: false,
                now: date("2026-09-10 20:16")
            )
        )
    }

    func testNewsSeasonWindow() {
        XCTAssertTrue(NewsSeason.isActive(season: "2026", now: date("2026-09-01 00:00")))
        XCTAssertTrue(NewsSeason.isActive(season: "2026", now: date("2027-02-15 12:00")))
        XCTAssertFalse(NewsSeason.isActive(season: "2026", now: date("2026-08-17 12:00")))
        XCTAssertFalse(NewsSeason.isActive(season: "2026", now: date("2027-02-16 12:00")))
        XCTAssertEqual(NewsSeason.nflHeadlineLimit, 20)
    }

    func testNewsSeasonDropsOffseasonArticles() {
        XCTAssertFalse(
            NewsSeason.contains(
                published: date("2026-08-13 12:00"),
                season: "2026",
                now: date("2026-08-17 12:00")
            )
        )
        XCTAssertTrue(
            NewsSeason.contains(
                published: date("2026-09-08 12:00"),
                season: "2026",
                now: date("2026-09-10 12:00")
            )
        )
    }

    private func date(_ value: String) -> Date {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = eastern
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.date(from: value)!
    }
}
