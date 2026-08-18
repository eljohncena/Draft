//
//  MatchupActivity.swift
//  Draft
//
//  Created by John Chavez on 8/17/26.
//

#if os(iOS) && !targetEnvironment(macCatalyst) && canImport(ActivityKit)
import ActivityKit
import Foundation

struct MatchupActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var myScore: Double
        var opponentScore: Double
        var myRecord: String
        var opponentRecord: String
        var myRank: Int
        var opponentRank: Int
    }

    var leagueName: String
    var week: Int
    var myTeam: String
    var opponentName: String
    var myUserID: String
}
#endif
