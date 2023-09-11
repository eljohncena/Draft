//
//  leagueInfo.swift
//  test
//
//  Created by John Chavez on 9/9/23.
//


import Foundation
import UIKit


struct LeagueInfo: Decodable {
    
    var totalRosters: Int
    var name: String
    var season: String
    
    enum CodingKeys: String, CodingKey {
        case totalRosters = "total_rosters"
        case name
        case season
    }
    
}
