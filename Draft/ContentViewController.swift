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
                    }
                    HStack {
                        VStack {
                            Text("Rankings")
                                .font(.title)
                            ForEach(manager.users , id:\.id) { user in
                                Text(user.metaData.teamName)
                                    .font(.body)
                                    .fontWeight(.bold)
                                Text(user.displayName)
                                    .font(.body)
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

