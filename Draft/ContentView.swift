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
        
        TabView {
//            let userAndRoster = manager.combineUsersAndRosters()
            @State var combinedUserInfo = manager.combineUsersAndMatchups(usersAndRosters: manager.combineUsersAndRosters())
            VStack{
                Text("\(manager.name)")
                    .font(.largeTitle)
                HStack{
                    Text("Week \(manager.week) Standings")
                        .font(.title2)
                        .padding(.bottom, 10)
                    // drop down menu to select week as well a buttons on both sides to go to each week
                }

                
                // Add accesibility tags. Review App Store guideline.
                
                NavigationStack{
                    List{
                        ForEach(combinedUserInfo.sorted{$0.matchups.points > $1.matchups.points}) { user in
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
            .tabItem{
                Label("Weekly", systemImage: "stairs")
            }
            MatchupsView(users: combinedUserInfo)
            .tabItem {
                Label("Matchups", systemImage: "arrow.down.right.and.arrow.up.left")
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

