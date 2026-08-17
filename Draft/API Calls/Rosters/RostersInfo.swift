//
//  RostersInfo.swift
//  Draft
//
//  Created by John Chavez on 9/10/23.
//

import Foundation

struct RostersInfo: Decodable, Hashable {
    static func == (lhs: RostersInfo, rhs: RostersInfo) -> Bool {
        return lhs.settings == rhs.settings && lhs.rosterID == rhs.rosterID && lhs.userID == rhs.userID && lhs.players == rhs.players && lhs.starters == rhs.starters
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(settings)
        hasher.combine(rosterID)
        hasher.combine(userID)
        hasher.combine(players)
        hasher.combine(starters)
    }
    
    
    var settings: Settings
    var rosterID: Int = 0
    var userID: String = ""
    var players: [String] = []
    var starters: [String] = []
    
    
    struct Settings: Decodable, Hashable {
        var wins: Int = 0
        var ties: Int = 0
        var losses: Int = 0
        var totalPoints: Double = 0
    }
    
    
    enum CodingKeys: String, CodingKey {
        case rosterID = "roster_id"
        case userID = "owner_id"
        case settings
        case players
        case starters
        
        enum SettingsCodingKeys: String, CodingKey {
            case wins
            case ties
            case losses
            case fpts
            case fptsDecimal = "fpts_decimal"
        }
        
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        do {
            rosterID = try container.decode(Int.self, forKey: .rosterID)
        }catch DecodingError.keyNotFound {
            rosterID = 0
            print("Failed to fetch RosterId")
        }
        
        userID = try container.decode(String.self, forKey: .userID)
        players = Self.decodeIDs(container, forKey: .players)
        starters = Self.decodeIDs(container, forKey: .starters)
        
        
        do {
            let settingsContainer = try container.nestedContainer(keyedBy: CodingKeys.SettingsCodingKeys.self, forKey: .settings)
            let wins = try settingsContainer.decode(Int.self, forKey: .wins)
            let ties = try settingsContainer.decode(Int.self, forKey: .ties)
            let losses = try settingsContainer.decode(Int.self, forKey: .losses)
            let fpts = try settingsContainer.decodeIfPresent(Double.self, forKey: .fpts) ?? 0
            let fptsDecimal = try settingsContainer.decodeIfPresent(Double.self, forKey: .fptsDecimal) ?? 0
            
            settings = Settings(
                wins: wins,
                ties: ties,
                losses: losses,
                totalPoints: fpts + fptsDecimal / 100.0
            )
        } catch DecodingError.keyNotFound {
            settings = Settings(wins: 0, ties: 0, losses: 0)
            print("Error decoding Settings Keys")
        }
        
    }

    private static func decodeIDs(_ container: KeyedDecodingContainer<CodingKeys>, forKey key: CodingKeys) -> [String] {
        if let values = try? container.decode([String].self, forKey: key) {
            return values
        }
        if let values = try? container.decode([Int].self, forKey: key) {
            return values.map(String.init)
        }
        guard var unkeyed = try? container.nestedUnkeyedContainer(forKey: key) else {
            return []
        }
        var ids: [String] = []
        while !unkeyed.isAtEnd {
            if let value = try? unkeyed.decode(String.self) {
                ids.append(value)
            } else if let value = try? unkeyed.decode(Int.self) {
                ids.append(String(value))
            } else {
                _ = try? unkeyed.decode(Bool.self)
            }
        }
        return ids
    }
}

extension RostersInfo {
    init(settings: Settings, rosterID: Int, userID: String, players: [String] = [], starters: [String] = []) {
        self.settings = settings
        self.rosterID = rosterID
        self.userID = userID
        self.players = players
        self.starters = starters
    }
}

