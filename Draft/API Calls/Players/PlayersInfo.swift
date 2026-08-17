//
//  PlayersInfo.swift
//  Draft
//
//  Created by John Chavez on 8/17/26.
//

import Foundation

struct PlayersInfo: Codable, Hashable {
    var playerID: String = ""
    var firstName: String = ""
    var lastName: String = ""
    var fullName: String = ""
    var position: String = ""
    var team: String = ""
    var espnID: String = ""
    var injuryStatus: String = ""

    var displayName: String {
        if !fullName.isEmpty {
            return fullName
        }
        let combined = [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
        return combined.isEmpty ? playerID : combined
    }

    var positionTeam: String {
        [position, team].filter { !$0.isEmpty }.joined(separator: " · ")
    }

    enum CodingKeys: String, CodingKey {
        case playerID = "player_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case fullName = "full_name"
        case position
        case team
        case espnID = "espn_id"
        case injuryStatus = "injury_status"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        firstName = Self.decodeString(container, .firstName)
        lastName = Self.decodeString(container, .lastName)
        fullName = Self.decodeString(container, .fullName)
        position = Self.decodeString(container, .position)
        team = Self.decodeString(container, .team)
        injuryStatus = Self.decodeString(container, .injuryStatus)
        espnID = Self.decodeString(container, .espnID)
        playerID = Self.decodeString(container, .playerID)
    }

    private static func decodeString(_ container: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) -> String {
        if let value = try? container.decode(String.self, forKey: key) {
            return value
        }
        if let value = try? container.decode(Int.self, forKey: key) {
            return String(value)
        }
        return ""
    }

    init(
        playerID: String,
        firstName: String = "",
        lastName: String = "",
        fullName: String = "",
        position: String = "",
        team: String = "",
        espnID: String = "",
        injuryStatus: String = ""
    ) {
        self.playerID = playerID
        self.firstName = firstName
        self.lastName = lastName
        self.fullName = fullName
        self.position = position
        self.team = team
        self.espnID = espnID
        self.injuryStatus = injuryStatus
    }
}
