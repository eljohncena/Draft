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
            ScrollView {
                VStack{
                    VStack {
                        Text(manager.name)
                            .font(.largeTitle)
//                        Text(String(manager.totalRoster))
                        Text("Season: \(manager.season)")
                            .font(.title2)
//                        Text("Week: \(week)")
//                          I need to make a variable that will update the week number as well as call
                    } .padding(.bottom)
                    HStack {
                        VStack {
                            Text("Teams")
                                .font(.title)
                            ForEach(manager.users, id:\.id) { user in
                                Text(user.metaData.teamName)
                                    .font(.body)
                                    .fontWeight(.bold)
                                Text(user.displayName)
                                    .font(.body)
                                HStack{
                                    if let userWins = manager.rosters.first(where: { $0.userID == user.userID }) {
                                        Text("Wins: \(userWins.settings.wins)")
                                        }
                                    if let userLosses = manager.rosters.first(where: { $0.userID == user.userID }) {
                                        Text("Losses: \(userLosses.settings.losses)")
                                        }
                                    if let userTies = manager.rosters.first(where: { $0.userID == user.userID }) {
                                        Text("Ties: \(userTies.settings.ties)")
                                        }
                                    
                                }
                                Divider()
                            }
                        }
//                        VStack {
//                            ForEach(manager.users , id:\.id) { user in
//                                Text(user.metaData.teamName)
//                            }
//                        }
                    }
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

