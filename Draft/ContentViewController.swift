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
                    HStack {
                        Text("Hello")
                        Text(manager.name)
                        Text(String(manager.totalRoster))
                        Text("Season: \(manager.season)")
                    }
                    
                    HStack{
                        ForEach(manager.users , id:\.id) { user in
                            Text(user.displayName)
//                            Text(user.metaData.teamName)
                        }
                    }
                }
            }.task
                {
                    await manager.startProcess()
                }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

