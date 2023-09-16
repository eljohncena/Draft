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
            Text(String("Total Players: \(manager.totalRoster)"))
            Text("Season: \(manager.season)")
                .font(.title2)
            Text("Week: \(manager.week)")
//              Add this bottom stack together so Name and and season arent static
        //  Potentially Team on Left and Opponent on right
        //  could also create static menu to be able to switch to favorite team and see stats
        // add accesibility tags. Review App Store guideline.
            VStack{

                let userAndRoster = manager.combineUsersAndRosters()
                let combinedUserInfo = manager.combineUsersAndMatchups(usersAndRosters: userAndRoster)
                
                
                NavigationView {
                    List(combinedUserInfo.sorted{$0.matchups.points > $1.matchups.points}) { user in
                        NavigationLink(destination: TeamInfoView(userTeamInfo: user)){
                            VStack{
                                Text(user.usersAndRosters.user.metaData.teamName)
                                    .font(.body)
                                    .fontWeight(.bold)
                                HStack{
                                    Text("\(user.usersAndRosters.userGameWinLossTie.settings.wins) - \(user.usersAndRosters.userGameWinLossTie.settings.ties) - \(user.usersAndRosters.userGameWinLossTie.settings.losses)")
                                        .font(.subheadline)
                                    }
                                Text("Points for: \(String(format: "%.2f", user.matchups.points))")
                                

                                
                                ForEach(combinedUserInfo.filter{$0.matchups.matchupID == user.matchups.matchupID}) { opponent in
                                    if user.usersAndRosters.user.metaData.teamName != opponent.usersAndRosters.user.metaData.teamName {
                                        Text("Opponent: \(opponent.usersAndRosters.user.metaData.teamName)")
                                    }
                                    
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

