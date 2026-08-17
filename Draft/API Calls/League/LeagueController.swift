//
//  LeagueController.swift
//  test
//
//  Created by John Chavez on 9/9/23.
//

import Foundation

class LeagueController {

    enum LeagueControllerError: Error, LocalizedError {
        case itemNotFound
        case decodingFailed
    }

    func fetchLeagueInfo() async throws -> LeagueInfo {
        try await SleeperClient.get("league/\(SleeperConfig.leagueID)")
    }
}

class LeaguesController {

    enum LeaguesControllerError: Error, LocalizedError {
        case itemNotFound
        case decodingFailed
    }

    func searchLeagues(query: String) async throws -> [LeagueSummary] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        var found: [LeagueSummary] = []
        var seen = Set<String>()

        func append(_ leagues: [LeagueSummary]) {
            for league in leagues where !league.leagueID.isEmpty && seen.insert(league.leagueID).inserted {
                found.append(league)
            }
        }

        if trimmed.allSatisfy(\.isNumber), let league = try? await fetchLeague(id: trimmed) {
            append([league])
        }

        if let user = try? await fetchUser(trimmed), !user.userID.isEmpty {
            let season = (try? await fetchNFLSeason()) ?? "2026"
            if let year = Int(season) {
                for y in stride(from: year, through: year - 3, by: -1) {
                    if let leagues = try? await fetchLeagues(userID: user.userID, season: String(y)) {
                        append(leagues)
                    }
                }
            }
        }

        return found
    }

    func fetchLeague(id: String) async throws -> LeagueSummary {
        try await SleeperClient.get("league/\(id)")
    }

    func fetchUser(_ usernameOrID: String) async throws -> SleeperUser {
        try await SleeperClient.get("user/\(usernameOrID)")
    }

    func fetchLeagues(userID: String, season: String) async throws -> [LeagueSummary] {
        try await SleeperClient.get("user/\(userID)/leagues/nfl/\(season)")
    }

    func fetchNFLSeason() async throws -> String {
        struct NFLState: Decodable {
            var season: String
        }
        let state: NFLState = try await SleeperClient.get("state/nfl")
        return state.season
    }
}
