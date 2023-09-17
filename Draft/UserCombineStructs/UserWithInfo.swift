//
//  UserData.swift
//  Draft
//
//  Created by John Chavez on 9/11/23.
//
//
import Foundation

struct UsersWithInfo: Hashable{
    static func == (lhs: UsersWithInfo, rhs: UsersWithInfo) -> Bool {
        return lhs.user == rhs.user && lhs.userGameWinLossTie == rhs.userGameWinLossTie
    }
    
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(user)
        hasher.combine(userGameWinLossTie)
    }
    
    var user: UsersInfo

    var userGameWinLossTie: RostersInfo

    init(user: UsersInfo, userGameWinLossTie: RostersInfo) {
        self.user = user
        self.userGameWinLossTie = userGameWinLossTie
    }
    

}


