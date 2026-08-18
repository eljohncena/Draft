//
//  LeagueLogicTests.swift
//  DraftTests
//

import XCTest
@testable import Draft

final class LeagueLogicTests: XCTestCase {

    func testPointAndRecordFormatting() {
        XCTAssertEqual(DraftFormat.points(12.3 as Float), "12.30")
        XCTAssertEqual(DraftFormat.points(8 as Double), "8.00")
        XCTAssertEqual(DraftFormat.record(wins: 3, ties: 1, losses: 2), "3–1–2")
    }

    func testWeekRecordCountsWinsAndPoints() {
        let weeks: [Int: [MatchupsInfo]] = [
            1: [
                MatchupsInfo(rosterID: 1, points: 120, matchupID: 8),
                MatchupsInfo(rosterID: 2, points: 90, matchupID: 8)
            ],
            2: [
                MatchupsInfo(rosterID: 1, points: 80, matchupID: 3),
                MatchupsInfo(rosterID: 2, points: 80, matchupID: 3)
            ]
        ]

        let record = WeekRecord.through(week: 2, rosterID: 1, matchupsByWeek: weeks)
        XCTAssertEqual(record.wins, 1)
        XCTAssertEqual(record.ties, 1)
        XCTAssertEqual(record.losses, 0)
        XCTAssertEqual(record.pointsFor, 200)
    }

    func testPulsePicksHighestScoreAndClosestMatchup() {
        let high = team(id: "a", roster: 1, name: "Wizards", points: 142, matchup: 4, player: "4984", playerPoints: 32)
        let low = team(id: "b", roster: 2, name: "South", points: 101, matchup: 4, player: "4046", playerPoints: 8)
        let players = [
            "4984": PlayersInfo(playerID: "4984", fullName: "Justin Jefferson"),
            "4046": PlayersInfo(playerID: "4046", fullName: "Christian McCaffrey")
        ]

        let rows = LeagueWeekPulse.rows(users: [high, low], players: players, week: 1)
        XCTAssertTrue(rows.contains { $0.id == "high-team" && $0.detail.contains("Wizards") })
        XCTAssertTrue(rows.contains { $0.id == "low-team" && $0.detail.contains("South") })
        XCTAssertTrue(rows.contains { $0.id == "closest" && $0.detail.contains("142.00") })
        XCTAssertTrue(rows.contains { $0.id == "high-player" && $0.detail.contains("Justin Jefferson") })
    }

    func testPulseEmptyWeekHasAPlaceholder() {
        let rows = LeagueWeekPulse.rows(users: [], players: [:], week: 3)
        XCTAssertEqual(rows.map(\.id), ["empty"])
        XCTAssertTrue(rows[0].detail.contains("Week 3") || rows[0].title.contains("Week 3"))
    }

    @MainActor
    func testVoteTallyPercents() {
        let votes = [
            MatchupBallot.Vote(leagueID: "1", week: 1, matchupID: 8, voterID: "me", winnerUserID: "left"),
            MatchupBallot.Vote(leagueID: "1", week: 1, matchupID: 8, voterID: "you", winnerUserID: "right"),
            MatchupBallot.Vote(leagueID: "1", week: 1, matchupID: 8, voterID: "them", winnerUserID: "left")
        ]
        let tally = MatchupBallot.Tally(votes: votes, leftUserID: "left", rightUserID: "right", voterID: "me")

        XCTAssertEqual(tally.total, 3)
        XCTAssertTrue(tally.hasVoted)
        XCTAssertEqual(tally.myWinnerUserID, "left")
        XCTAssertEqual(tally.percent(for: "left"), 67)
        XCTAssertEqual(tally.percent(for: "right"), 33)
        XCTAssertNil(tally.percent(for: "other"))
    }

    private func team(
        id: String,
        roster: Int,
        name: String,
        points: Float,
        matchup: Int,
        player: String,
        playerPoints: Float
    ) -> UsersAndMatchups {
        let user = UsersInfo(
            userID: id,
            displayName: name,
            avatarImage: nil,
            metaData: .init(teamName: name, avatarURL: "")
        )
        let rosterInfo = RostersInfo(
            settings: .init(wins: 0, ties: 0, losses: 0, totalPoints: Double(points)),
            rosterID: roster,
            userID: id,
            players: [player],
            starters: [player]
        )
        return UsersAndMatchups(
            usersAndRosters: UsersWithInfo(user: user, userGameWinLossTie: rosterInfo),
            matchups: MatchupsInfo(
                rosterID: roster,
                points: points,
                matchupID: matchup,
                playerPoints: [player: playerPoints]
            )
        )
    }
}
