//
//  UsersInfo.swift
//  Draft
//
//  Created by John Chavez on 9/10/23.
//

import Foundation
import SwiftUI

struct UsersInfo: Codable, Identifiable {
    
    var userID: String
    var displayName: String
    var id = UUID()
    var metaData: MetaData
    
    struct MetaData: Codable{
        var teamName: String
    }
        
    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case displayName = "display_name"
        case metaData = "metadata"
        
        enum MetaDataCodingKeys: String, CodingKey {
            case teamName = "team_Name"
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userID = try container.decode(String.self, forKey: .userID)
        displayName = try container.decode(String.self, forKey: .displayName)
        
        let MetaDataContainer = try container.nestedContainer(keyedBy: CodingKeys.MetaDataCodingKeys.self, forKey: .metaData)
        let teamName = try MetaDataContainer.decode(String.self, forKey: .teamName)
        
        metaData = MetaData(teamName: teamName)
    }
}
