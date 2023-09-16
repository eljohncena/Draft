//
//  UsersAndMatchups.swift
//  Draft
//
//  Created by John Chavez on 9/12/23.
//

import Foundation

struct UsersAndMatchups: Identifiable {
    var usersAndRosters: UsersWithInfo
    var matchups: MatchupsInfo
    var id =  UUID()
    
    init(usersAndRosters: UsersWithInfo, matchups: MatchupsInfo) {
        self.usersAndRosters = usersAndRosters
        self.matchups = matchups
    }
}

