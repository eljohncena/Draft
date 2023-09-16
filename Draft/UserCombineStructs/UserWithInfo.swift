//
//  UserData.swift
//  Draft
//
//  Created by John Chavez on 9/11/23.
//
//
import Foundation

struct UsersWithInfo{

    
    let user: UsersInfo

    let userGameWinLossTie: RostersInfo

    init(user: UsersInfo, userGameWinLossTie: RostersInfo) {
        self.user = user
        self.userGameWinLossTie = userGameWinLossTie
    }
    

}


