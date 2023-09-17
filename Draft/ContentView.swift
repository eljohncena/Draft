//
//  ContentView.swift
//  test
//
//  Created by John Chavez on 9/9/23.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject var manager = ContentViewController()
    var body: some View {
        VStack{
            Text("\(manager.name)")
                .font(.largeTitle)
//            Text(String("Total Players: \(manager.totalRoster)"))
//            Text("Season: \(manager.season)")
            HStack{
                
                Text("Week \(manager.week) Matchups")
                    .font(.title2)
                    .padding(.bottom, 10)
                // drop down menu to select week as well a buttons on both sides to go to each week
                }
            

        // Static menu or Navigation Split to be able to switch to favorite team and see stats
            // maybe Navigation SplitView
        // Add accesibility tags. Review App Store guideline.
//            VStack{

            let userAndRoster = manager.combineUsersAndRosters()
            let combinedUserInfo = manager.combineUsersAndMatchups(usersAndRosters: userAndRoster)
                
                
                // add user avatars above team names

            NavigationStack{
                List{
                    ForEach(combinedUserInfo.sorted{$0.matchups.points > $1.matchups.points}) { user in
                        NavigationLink(value: user){
                            HStack{
                                HStack{
                                    VStack{
                                        Text(user.usersAndRosters.user.metaData.teamName)
                                            .fontWeight(.bold)
                                        HStack{
                                            Text("\(user.usersAndRosters.userGameWinLossTie.settings.wins) - \(user.usersAndRosters.userGameWinLossTie.settings.ties) - \(user.usersAndRosters.userGameWinLossTie.settings.losses)")
                                                .font(.subheadline)
                                        }
                                        Text("Points for: \(String(format: "%.2f", user.matchups.points))")
                                    }
                                    .frame(maxWidth: .infinity, alignment: .center)
                                }
                                HStack{
                                    Text("VS")
                                }
                                .frame(minWidth: 10, alignment: .center)
                                HStack{
                                    ForEach(combinedUserInfo.filter{$0.matchups.matchupID == user.matchups.matchupID}) { opponent in
                                        if user.usersAndRosters.user.metaData.teamName != opponent.usersAndRosters.user.metaData.teamName {
                                            VStack{
                                                Text(opponent.usersAndRosters.user.metaData.teamName)
                                                    .fontWeight(.bold)
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
                }

            }
                .padding([.top, .bottom], 10)
                .navigationDestination(for: UsersAndMatchups.self) { user in
                    VStack{
                        Text(user.usersAndRosters.user.metaData.teamName)
                        }
                    }

        }

//            UIBlurEffect.Style.systemThinMaterial
//            Look up how to confim to View
                
                    
        }.task{
            await manager.startProcess()
        }
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

