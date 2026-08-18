//
//  NFLScoreboardTests.swift
//  DraftTests
//

import XCTest
@testable import Draft

final class NFLScoreboardTests: XCTestCase {

    func testDecodesFinalGameAndMarksWinner() throws {
        let games = try NFLScoreboard.games(from: Data(Self.sampleJSON.utf8))
        XCTAssertEqual(games.map(\.id), ["2", "1"])

        let live = games[0]
        XCTAssertEqual(live.awayAbbr, "KC")
        XCTAssertEqual(live.homeAbbr, "BUF")
        XCTAssertEqual(live.awayScore, "14")
        XCTAssertEqual(live.homeScore, "7")
        XCTAssertTrue(live.isLive)
        XCTAssertEqual(live.chipStatus, "LIVE")

        let final = games[1]
        XCTAssertEqual(final.awayAbbr, "DET")
        XCTAssertEqual(final.homeAbbr, "CIN")
        XCTAssertEqual(final.awayScore, "14")
        XCTAssertEqual(final.homeScore, "16")
        XCTAssertTrue(final.homeWon)
        XCTAssertFalse(final.awayWon)
        XCTAssertTrue(final.isFinal)
        XCTAssertEqual(final.chipStatus, "Final")
        XCTAssertTrue(final.accessibilityLabel.contains("CIN won"))
    }

    func testUpcomingGameHidesZeroScores() throws {
        let json = """
        {"events":[{"id":"3","date":"2026-08-20T00:00Z","status":{"type":{"state":"pre","shortDetail":"Thu 8:00 PM"}},"competitions":[{"competitors":[
          {"homeAway":"home","score":"0","team":{"abbreviation":"HOU"}},
          {"homeAway":"away","score":"0","team":{"abbreviation":"LV"}}
        ]}]}]}
        """
        let games = try NFLScoreboard.games(from: Data(json.utf8))
        XCTAssertEqual(games.count, 1)
        XCTAssertFalse(games[0].showsScore)
        XCTAssertFalse(games[0].isLive)
        XCTAssertEqual(games[0].awayAbbr, "LV")
        XCTAssertEqual(games[0].homeAbbr, "HOU")
    }

    private static let sampleJSON = """
    {
      "events": [
        {
          "id": "1",
          "date": "2026-08-13T23:00Z",
          "status": { "type": { "state": "post", "shortDetail": "Final" } },
          "competitions": [{
            "competitors": [
              { "homeAway": "home", "score": "16", "winner": true, "team": { "abbreviation": "CIN" } },
              { "homeAway": "away", "score": "14", "winner": false, "team": { "abbreviation": "DET" } }
            ]
          }]
        },
        {
          "id": "2",
          "date": "2026-09-13T17:00Z",
          "status": { "type": { "state": "in", "shortDetail": "Q2 4:12" } },
          "competitions": [{
            "competitors": [
              { "homeAway": "home", "score": "7", "winner": false, "team": { "abbreviation": "BUF" } },
              { "homeAway": "away", "score": "14", "winner": false, "team": { "abbreviation": "KC" } }
            ]
          }]
        }
      ]
    }
    """
}
