//
//  UsersAndMatchups.swift
//  Draft
//
//  Created by John Chavez on 9/12/23.
//

import Foundation

struct UsersAndMatchups: Identifiable, Hashable {
    static func == (lhs: UsersAndMatchups, rhs: UsersAndMatchups) -> Bool {
        return lhs.usersAndRosters == rhs.usersAndRosters && lhs.matchups == rhs.matchups
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(usersAndRosters)
        hasher.combine(matchups)
    }
    
    
    var usersAndRosters: UsersWithInfo
    var matchups: MatchupsInfo
    var id =  UUID()
    
    init(usersAndRosters: UsersWithInfo, matchups: MatchupsInfo) {
        self.usersAndRosters = usersAndRosters
        self.matchups = matchups
    }
}

