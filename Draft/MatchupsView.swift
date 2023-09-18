//
//  MatchupsView.swift
//  Draft
//
//  Created by John Chavez on 9/17/23.
//

import SwiftUI

struct MatchupsView: View {
    
    var users: [UsersAndMatchups]
    
    var body: some View {
        VStack{
            List{
                ForEach(users.sorted{$0.matchups.points > $1.matchups.points}) { user in
                        HStack{
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
//                                    Text("\(user.matchups.rosterID)")
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                            }
                            HStack{
                                Text("VS")
                            }
                            .frame(minWidth: 10, alignment: .center)
                            HStack{
                                ForEach(users.filter{$0.matchups.matchupID == user.matchups.matchupID}) { opponent in
                                    if user.usersAndRosters.user.metaData.teamName != opponent.usersAndRosters.user.metaData.teamName {
                                        VStack{
                                            Image(uiImage: opponent.usersAndRosters.user.avatarImage!)
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 50, height: 50)
                                            Text(opponent.usersAndRosters.user.metaData.teamName)
                                                .fontWeight(.bold)
                                                .multilineTextAlignment(.center)
                                            HStack{
                                                Text("\(opponent.usersAndRosters.userGameWinLossTie.settings.wins) - \(opponent.usersAndRosters.userGameWinLossTie.settings.ties) - \(opponent.usersAndRosters.userGameWinLossTie.settings.losses)")
                                                    .font(.subheadline)
                                            }
                                            Text("Points for: \(String(format: "%.2f", opponent.matchups.points))")
                                        }
                                        .frame(maxWidth: .infinity, alignment: .center)
                                    }
                                }
                            }
                        }
                    }
                    .padding([.top, .bottom], 10)
            }
        }
    }
}

struct MatchupsView_Previews: PreviewProvider {
    static var previews: some View {
        
        let combinedUserInfo = [UsersAndMatchups(usersAndRosters: UsersWithInfo(user: UsersInfo(userID: "98782", displayName: "NotGreenBay", avatarImage: UIImage(systemName: "questionmark")!, metaData: UsersInfo.MetaData(teamName: "NotGreenBay", avatarURL: "")), userGameWinLossTie: RostersInfo(settings: RostersInfo.Settings(), rosterID: 1, userID: "23")), matchups: MatchupsInfo(rosterID: 1, points: 100.0, matchupID: 1)),
                                UsersAndMatchups(usersAndRosters: UsersWithInfo(user: UsersInfo(userID: "12345", displayName: "Patriots", avatarImage: UIImage(systemName: "questionmark")!, metaData: UsersInfo.MetaData(teamName: "NotPatriotsBecauseBrady", avatarURL: "")), userGameWinLossTie: RostersInfo(settings: RostersInfo.Settings(), rosterID: 2, userID: "23")), matchups: MatchupsInfo(rosterID: 2, points: 89.0, matchupID: 1))]
        
        return MatchupsView(users: combinedUserInfo)
    }
}
