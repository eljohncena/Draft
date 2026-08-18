//
//  NewsItemTests.swift
//  DraftTests
//

import XCTest
@testable import Draft

final class NewsItemTests: XCTestCase {

    private let jefferson = PlayersInfo(
        playerID: "4984",
        firstName: "Justin",
        lastName: "Jefferson",
        fullName: "Justin Jefferson",
        team: "MIN"
    )

    private let hill = PlayersInfo(
        playerID: "4034",
        firstName: "Tyreek",
        lastName: "Hill",
        fullName: "Tyreek Hill",
        team: "MIA"
    )

    func testGenericHeadlineDoesNotMatchEveryPlayer() {
        let item = article(
            title: "NFL preseason roundup",
            summary: "Sixteen games are in the books.",
            names: []
        )

        XCTAssertFalse(item.mentions(player: jefferson))
        XCTAssertFalse(item.mentions(player: hill))
    }

    func testESPNAthleteTagMatchesOnlyThatPlayer() {
        let item = article(
            title: "Vikings stay aggressive",
            summary: "Minnesota looks set at receiver.",
            names: ["Justin Jefferson"]
        )

        XCTAssertTrue(item.mentions(player: jefferson))
        XCTAssertFalse(item.mentions(player: hill))
    }

    func testFullNameInHeadlineMatches() {
        let item = article(
            title: "Justin Jefferson expected to play",
            summary: "Minnesota lists him as active."
        )

        XCTAssertTrue(item.mentions(player: jefferson))
        XCTAssertFalse(item.mentions(player: hill))
    }

    func testRelatedPlayerIDMatchesEvenWithoutName() {
        let item = NewsItem(
            id: "sleeper-4984-1",
            title: "Practice report",
            summary: "Limited in walkthrough.",
            source: "Sleeper",
            playerNames: [],
            teams: [],
            relatedPlayerIDs: ["4984"]
        )

        XCTAssertTrue(item.mentions(player: jefferson))
        XCTAssertFalse(item.mentions(player: hill))
    }

    func testShortLastNameAloneIsNotEnough() {
        let item = article(
            title: "Capitol Hill briefing",
            summary: "No football notes today."
        )

        XCTAssertFalse(item.mentions(player: hill))
    }

    func testFirstAndLastNameTogetherMatch() {
        let item = article(
            title: "Hill, Tyreek stay on pace",
            summary: "Miami expects Tyreek Hill to return kicks."
        )

        XCTAssertTrue(item.mentions(player: hill))
        XCTAssertFalse(item.mentions(player: jefferson))
    }

    func testSearchMatchesTitleAndTags() {
        let item = article(
            title: "Vikings stay aggressive",
            summary: "Receiver room update.",
            names: ["Justin Jefferson"]
        )

        XCTAssertTrue(item.matches("jefferson"))
        XCTAssertTrue(item.matches("Vikings"))
        XCTAssertFalse(item.matches("Mahomes"))
        XCTAssertTrue(item.matches("  "))
    }

    func testTeamAliases() {
        XCTAssertEqual(NFLTeam.aliases(for: "WAS"), ["WAS", "WSH"])
        XCTAssertEqual(NFLTeam.aliases(for: "jax"), ["JAC", "JAX"])
        XCTAssertEqual(NFLTeam.aliases(for: "MIN"), ["MIN"])
        XCTAssertTrue(NFLTeam.aliases(for: "").isEmpty)

        let item = article(title: "Washington notes", summary: "", names: [], teams: ["WSH"])
        XCTAssertTrue(item.mentions(team: "WAS"))
        XCTAssertFalse(item.mentions(team: "MIN"))
    }

    private func article(
        title: String,
        summary: String,
        names: [String] = [],
        teams: [String] = []
    ) -> NewsItem {
        NewsItem(
            id: title,
            title: title,
            summary: summary,
            source: "ESPN",
            playerNames: names,
            teams: teams
        )
    }
}
