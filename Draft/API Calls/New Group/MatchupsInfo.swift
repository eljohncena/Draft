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

    func mentions(player: PlayersInfo) -> Bool {
        let names = Set(([player.displayName] + playerNames).map { $0.lowercased() }.filter { !$0.isEmpty })
        if playerNames.contains(where: { $0.compare(player.displayName, options: .caseInsensitive) == .orderedSame }) {
            return true
        }

        let haystack = (title + " " + summary).lowercased()
        let fullName = player.displayName.lowercased()
        if fullName.count >= 5 && haystack.contains(fullName) {
            return true
        }

        return names.contains(fullName)
    }

    func mentions(team: String) -> Bool {
        let aliases = NFLTeam.aliases(for: team)
        return teams.contains { aliases.contains($0.uppercased()) }
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

