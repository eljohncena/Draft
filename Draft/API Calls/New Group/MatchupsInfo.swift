//
//  MatchupsInfo.swift
//  Draft
//
//  Created by John Chavez on 9/12/23.
//

import Foundation
import SwiftUI

struct MatchupsInfo: Decodable {
    
    var rosterID: Int = 0
    var points: Float = 0.00
    var matchupID: Int = 0
    
    enum CodingKeys: String, CodingKey {
        case rosterID = "roster_id"
        case points
        case matchupID = "matchup_id"
    }
    
    
    init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.points = try container.decode(Float.self, forKey: .points)
        self.matchupID = try container.decode(Int.self, forKey: .matchupID)
        do {
            self.rosterID = try container.decode(Int.self, forKey: .rosterID)

            
        } catch DecodingError.keyNotFound {
            print("Error keynotFound from MatchupsInfo Struct")
            rosterID = 0
            points = 0.00
            matchupID = 0
        }


    }
}

extension MatchupsInfo {
    init(rosterID: Int, points: Float, matchupID: Int) {
        self.rosterID = rosterID
        self.points = points
        self.matchupID = matchupID
    }
}

