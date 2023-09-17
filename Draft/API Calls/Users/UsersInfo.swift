//
//  UsersInfo.swift
//  Draft
//
//  Created by John Chavez on 9/10/23.
//

import Foundation
import SwiftUI

struct UsersInfo: Decodable, Identifiable, Hashable {
    static func == (lhs: UsersInfo, rhs: UsersInfo) -> Bool {
        return lhs.userID == rhs.userID && lhs.metaData == rhs.metaData && lhs.displayName == rhs.displayName
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(userID)
        hasher.combine(metaData)
        hasher.combine(displayName)
    }
    
    var userID: String = ""
    var metaData: MetaData
    var displayName: String = ""
    var id = UUID()
    
    struct MetaData: Decodable, Hashable{
        var teamName: String = ""
    }
        
    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case displayName = "display_name"
        case metaData = "metadata"
        
        enum MetaDataCodingKeys: String, CodingKey {
            case teamName = "team_name"
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userID = try container.decode(String.self, forKey: .userID)
        displayName = try container.decode(String.self, forKey: .displayName)
        
        
        do {
            let MetaDataContainer = try container.nestedContainer(keyedBy: CodingKeys.MetaDataCodingKeys.self, forKey: .metaData)
            let teamName = try MetaDataContainer.decode(String.self, forKey: .teamName)
            
            metaData = MetaData(teamName: teamName)
        } catch DecodingError.keyNotFound {
            metaData = MetaData(teamName: "No Team Name")
        }
        
    }
}

extension UsersInfo {
    init(userID: String, displayName: String, metaData: MetaData) {
        self.userID = userID
        self.displayName = displayName
        self.metaData = metaData
    }
}
