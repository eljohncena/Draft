////
////  TeamInfoView.swift
////  Draft
////
////  Created by John Chavez on 9/11/23.
////
//
//import SwiftUI
//
//struct TeamInfoView: View {
//    
//    var userTeamInfo: UsersAndMatchups
//    
//    var body: some View {
//        ScrollView{
//            VStack{
//                ForEach(userTeamInfo, id: \.id){ user in
//                    Text(user.usersAndRosters.user.metaData.teamName)
//                }
//            }
//                
//        }
//        
//    }
//}
//
//struct TeamInfoView_Previews: PreviewProvider {
//    static var previews: some View {
//        let usersAndMatchups = UsersAndMatchups(usersAndRosters: UsersWithInfo(user: UsersInfo(userID: "", displayName: "", metaData: UsersInfo.MetaData()), userGameWinLossTie: RostersInfo(settings: RostersInfo.Settings(), rosterID: 0, userID: "")), matchups: MatchupsInfo(rosterID: 0, points: 0.00, matchupID: 0))
//        
//        TeamInfoView(userTeamInfo: usersAndMatchups)
//    }
//}
