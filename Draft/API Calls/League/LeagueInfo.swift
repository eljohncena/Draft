//
//  leagueInfo.swift
//  test
//
//  Created by John Chavez on 9/9/23.
//


import Foundation
import UIKit


struct LeagueInfo: Decodable {
    
    var totalRosters: Int = 0
    var name: String = ""
    var season: String = ""
    
    var settings: Settings
    struct Settings {
        var leg: Int
    }
    
    enum CodingKeys: String, CodingKey {
        case totalRosters = "total_rosters"
        case name
        case season
        case settings
        
        enum SettingsCodingKeys: String, CodingKey {
            case leg
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.totalRosters = try container.decode(Int.self, forKey: .totalRosters)
        self.name = try container.decode(String.self, forKey: .name)
        self.season = try container.decode(String.self, forKey: .season)
        
        do {
            
            let settingsContainer = try container.nestedContainer(keyedBy: CodingKeys.SettingsCodingKeys.self, forKey: .settings)
            let leg = try settingsContainer.decode(Int.self, forKey: .leg )
            settings = Settings(leg: leg)
        } catch DecodingError.keyNotFound {
            print("Error Decoding LeagueInfo leg")
            settings = Settings(leg: 0)
        }

    }
    
}
