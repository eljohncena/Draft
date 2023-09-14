//
//  RostersInfo.swift
//  Draft
//
//  Created by John Chavez on 9/10/23.
//

import Foundation

struct RostersInfo: Decodable {
    
    var settings: Settings
    var rosterID: Int = 0
    var userID: String = ""
    
    
    struct Settings: Decodable {
        var wins: Int = 0
        var ties: Int = 0
        var losses: Int = 0
    }
    
    
    enum CodingKeys: String, CodingKey {
        case rosterID = "roster_id"
        case userID = "owner_id"
        case settings
        
        enum SettingsCodingKeys: String, CodingKey {
            case wins
            case ties
            case losses
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
        
        
        do {
            let settingsContainer = try container.nestedContainer(keyedBy: CodingKeys.SettingsCodingKeys.self, forKey: .settings)
            let wins = try settingsContainer.decode(Int.self, forKey: .wins)
            let ties = try settingsContainer.decode(Int.self, forKey: .ties)
            let losses = try settingsContainer.decode(Int.self, forKey: .losses)
            
            settings = Settings(wins: wins, ties: ties, losses: losses)
        } catch DecodingError.keyNotFound {
            settings = Settings(wins: 0, ties: 0, losses: 0)
            print("Error decoding Roster Keys")
        }
        
    }
}

extension RostersInfo {
    init(settings: Settings, rosterID: Int, userID: String) {
        self.settings = settings
        self.rosterID = rosterID
        self.userID = userID
    }
}

