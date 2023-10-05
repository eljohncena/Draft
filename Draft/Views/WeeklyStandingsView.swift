//
//  WeeklyStandingsView.swift
//  Draft
//
//  Created by John Chavez on 9/19/23.
//

import SwiftUI

struct WeeklyStandingsView: View {
    
    var users: [UsersAndMatchups]
    
    var body: some View {
        HStack{
//            Text("Week \(manager.week) Standings")
//                .font(.title2)
//                .padding(.bottom, 10)
            // drop down menu to select week as well a buttons on both sides to go to each week
        }
        NavigationStack {
            List{
                ForEach(users.sorted{$0.matchups.points > $1.matchups.points}) { user in
                    NavigationLink(value: user){
                        HStack{
                            VStack{
                                Image(uiImage: user.usersAndRosters.user.avatarImage!)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 50)
                                Text(user.usersAndRosters.user.metaData.teamName)
                                    .fontWeight(.bold)
                                    .multilineTextAlignment(.center)
                                
                                HStack{
                                    Text("\(user.usersAndRosters.userGameWinLossTie.settings.wins) - \(user.usersAndRosters.userGameWinLossTie.settings.ties) - \(user.usersAndRosters.userGameWinLossTie.settings.losses)")
                                        .font(.subheadline)
                                }
                                Text("Points for: \(String(format: "%.2f", user.matchups.points))")
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                }
            }
            .navigationDestination(for: UsersAndMatchups.self) { platform in
                Text(platform.usersAndRosters.user.metaData.teamName)
                }
        }
    }
}

struct WeeklyStandingsView_Previews: PreviewProvider {
    static var previews: some View {
        
        let combinedUserInfo = [UsersAndMatchups(usersAndRosters: UsersWithInfo(user: UsersInfo(userID: "98782", displayName: "NotGreenBay", avatarImage: UIImage(systemName: "questionmark")!, metaData: UsersInfo.MetaData(teamName: "NotGreenBay", avatarURL: "")), userGameWinLossTie: RostersInfo(settings: RostersInfo.Settings(), rosterID: 1, userID: "23")), matchups: MatchupsInfo(rosterID: 1, points: 100.0, matchupID: 1)),
                                UsersAndMatchups(usersAndRosters: UsersWithInfo(user: UsersInfo(userID: "12345", displayName: "Patriots", avatarImage: UIImage(systemName: "questionmark")!, metaData: UsersInfo.MetaData(teamName: "NotPatriotsBecauseBrady", avatarURL: "")), userGameWinLossTie: RostersInfo(settings: RostersInfo.Settings(), rosterID: 2, userID: "23")), matchups: MatchupsInfo(rosterID: 2, points: 89.0, matchupID: 1))]
        
        return MatchupsView(users: combinedUserInfo)
    }
}

