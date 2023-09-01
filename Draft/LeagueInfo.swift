//
//  LeagueInfo.swift
//  Draft
//
//  Created by John Chavez on 8/31/23.
//

import Foundation
import UIKit

struct LeagueInfo: Codable {
    var totalRoster: Int
    var sport: String
    var seasonType: String
    var season: String
    var rosterPositions: [Int]
    var leagueName: String
    var leagueId: Int
    var draftId: Int
    var url: URL

    enum CodingKeys: String, CodingKey {
        case totalRoster
        case sport
        case seasonType
        case season
        case rosterPositions
        case leagueName
        case leagueId
        case draftId
        case url
    }
}
