//
//  TeamInfoView.swift
//  Draft
//
//  Created by John Chavez on 9/11/23.
//

import SwiftUI

struct TeamInfoView: View {
    
    var userTeamInfo: UsersAndMatchups
    
    var body: some View {
        ScrollView{
            VStack{
                Text(userTeamInfo.usersAndRosters.user.displayName)
                
            }
        }
        
    }
}

//struct TeamInfoView_Previews: PreviewProvider {
//    static var previews: some View {
//
////        let userWithInfo = UsersWithInfo(
////            user: user(MetaData(t)),
////            userGameWinLossTie: RostersInfo.Settings(wins: 10, ties: 2, losses: 5)
////        )
////        let userWithInfo = UsersWithInfo(
////            user: User(id: 1, displayName: "User 1", wins: 10, losses: 5, ties: 2),
////            userGameWinLossTie: RostersInfo(wins: 10, losses: 5, ties: 2)
////        )
//
//        TeamInfoView(userTeamInfo: UsersWithInfo)
//    }
//}
