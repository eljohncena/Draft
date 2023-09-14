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
                Text(manager.name)
                    .font(.largeTitle)
                Text(String("Total Players: \(manager.totalRoster)"))
                Text("Season: \(manager.season)")
                    .font(.title2)
                //                        Text("Week: \(week)")
                //                          I need to make a variable that will update the week number as well as call
                
                VStack{

                let userAndRoster = manager.combineUsersAndRosters()
                let combinedUserInfo = manager.combineUsersAndMatchups(usersAndRosters: userAndRoster)
                
                    ForEach(combinedUserInfo) { user1 in
                        ForEach(combinedUserInfo) { user2 in
                            if user1.matchups.matchupID == user2.matchups.matchupID{
                                Text("\(user1.usersAndRosters.user.metaData.teamName) vs  \(user2.usersAndRosters.user.metaData.teamName)")
                            }
                        }

                    }
                    
                    //Check about index iteration ^
                    
                NavigationView {
                    List(combinedUserInfo.sorted{$0.matchups.points > $1.matchups.points}) { user in
                        NavigationLink(destination: TeamInfoView(userTeamInfo: user)){
                            VStack{
                                Text(user.usersAndRosters.user.metaData.teamName)
                                    .font(.body)
                                    .fontWeight(.bold)
                                Text("Points: \(user.matchups.points)")
                                HStack{
                                    Text("Wins: \(user.usersAndRosters.userGameWinLossTie.settings.wins)")
                                    Text("Ties: \(user.usersAndRosters.userGameWinLossTie.settings.ties)")
                                    Text("Losses: \(user.usersAndRosters.userGameWinLossTie.settings.losses)")
                                    }
                                }
                            .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .navigationTitle("Teams")
                            .navigationBarTitleDisplayMode(.inline)
                        }
                    }
                        
                        
//                      I need to convert this to navigation stack later. Unsure why code below isnt working. Alterneatives require
//                        all structs to become Hashable however it then requires "user" to become Binding Bool type; user is type                                  UsersWithInfo
//
//                        NavigationStack{
//                            ForEach(users, id:\.user.id) { user in
//
//                                NavigationLink(destination: TeamInfoView(userTeamInfo: user)) {
//                                    Text("Wins: \(user.userGameWinLossTie.wins)")
//                                }
//                            }
//
////                            .navigationDestination(for: UsersWithInfo.self) { user in
////                                TeamInfoView(userTeamInfo: user)
////                            }
//                        }
                    }
                        
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

