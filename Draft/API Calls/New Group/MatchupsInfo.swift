//
//  MatchupsInfo.swift
//  Draft
//
//  Created by John Chavez on 9/12/23.
//

import Foundation
import SwiftUI

struct MatchupsInfo: Decodable, Hashable {
    
    static func == (lhs: MatchupsInfo, rhs: MatchupsInfo) -> Bool {
        return lhs.rosterID == rhs.rosterID && lhs.points == rhs.points && lhs.matchupID == rhs.matchupID && lhs.playerPoints == rhs.playerPoints
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(rosterID)
        hasher.combine(points)
        hasher.combine(matchupID)
        hasher.combine(playerPoints)
    }
    
    
    var rosterID: Int = 0
    var points: Float = 0.00
    var matchupID: Int = 0
    var playerPoints: [String: Float] = [:]
    
    enum CodingKeys: String, CodingKey {
        case rosterID = "roster_id"
        case points
        case matchupID = "matchup_id"
        case playerPoints = "players_points"
    }
    
    
    init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.points = try container.decode(Float.self, forKey: .points)
        self.matchupID = try container.decode(Int.self, forKey: .matchupID)
        self.playerPoints = try container.decodeIfPresent([String: Float].self, forKey: .playerPoints) ?? [:]
        do {
            self.rosterID = try container.decode(Int.self, forKey: .rosterID)

            
        } catch DecodingError.keyNotFound {
            print("Error keynotFound from MatchupsInfo Struct")
            rosterID = 0
            points = 0.00
            matchupID = 0
            playerPoints = [:]
        }


    }
}

extension MatchupsInfo {
    init(rosterID: Int, points: Float, matchupID: Int, playerPoints: [String: Float] = [:]) {
        self.rosterID = rosterID
        self.points = points
        self.matchupID = matchupID
        self.playerPoints = playerPoints
    }
}

struct NewsItem: Identifiable, Hashable {
    var id: String
    var title: String
    var summary: String
    var source: String
    var url: URL?
    var published: Date?
    var imageURL: URL?
    var playerNames: [String]
    var teams: [String]
    var relatedPlayerIDs: [String] = []

    func mentions(player: PlayersInfo) -> Bool {
        if !player.playerID.isEmpty, relatedPlayerIDs.contains(player.playerID) {
            return true
        }

        let tagged = playerNames.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        let display = player.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let full = player.fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let first = player.firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let last = player.lastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let haystack = (title + " " + summary).lowercased()

        if tagged.contains(where: { Self.sameName($0, display) || Self.sameName($0, full) }) {
            return true
        }

        if Self.containsPhrase(display, in: haystack) || Self.containsPhrase(full, in: haystack) {
            return true
        }

        if first.count >= 2, last.count >= 4,
           Self.containsWord(first, in: haystack),
           Self.containsWord(last, in: haystack) {
            return true
        }

        if last.count >= 5, tagged.contains(where: { Self.sameName($0, last) }),
           (first.isEmpty || Self.containsWord(first, in: haystack)) {
            return true
        }

        return false
    }

    private static func sameName(_ lhs: String, _ rhs: String) -> Bool {
        !lhs.isEmpty && !rhs.isEmpty && lhs.compare(rhs, options: .caseInsensitive) == .orderedSame
    }

    private static func containsPhrase(_ phrase: String, in haystack: String) -> Bool {
        let needle = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
        guard needle.count >= 5 else { return false }
        return containsWord(needle, in: haystack)
    }

    private static func containsWord(_ needle: String, in haystack: String) -> Bool {
        let trimmed = needle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let escaped = NSRegularExpression.escapedPattern(for: trimmed.lowercased())
        let pattern = "(?<![\\p{L}\\p{N}])\(escaped)(?![\\p{L}\\p{N}])"
        return haystack.range(of: pattern, options: .regularExpression) != nil
    }

    func mentions(team: String) -> Bool {
        let aliases = NFLTeam.aliases(for: team)
        return teams.contains { aliases.contains($0.uppercased()) }
    }

    func matches(_ query: String) -> Bool {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return true }
        let haystack = ([title, summary, source] + playerNames + teams)
            .joined(separator: " ")
        return haystack.localizedCaseInsensitiveContains(needle)
    }
}

struct PlayerNewsRoute: Hashable {
    var playerID: String
    var weekPoints: Double
}

enum NFLTeam {
    static func aliases(for team: String) -> Set<String> {
        switch team.uppercased() {
        case "WAS", "WSH":
            return ["WAS", "WSH"]
        case "JAC", "JAX":
            return ["JAC", "JAX"]
        case "LA", "LAR":
            return ["LA", "LAR"]
        default:
            let value = team.uppercased()
            return value.isEmpty ? [] : [value]
        }
    }
}

