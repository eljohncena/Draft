//
//  ContentViewController.swift
//  test
//
//  Created by John Chavez on 9/9/23.
//

import Foundation
import SwiftUI

class ContentViewController: ObservableObject{
    let leagueController = LeagueController()
    let userController = UsersController()
    
    @Published var name = ""
    @Published var totalRoster = 0
    @Published var season = ""
    @Published var users: [UsersInfo] = []
    
    
    func startProcess() async {
        do {
            let info = try await leagueController.fetchLeagueInfo()
            print("League info fetch successful")
            
            let userInfo = try await userController.fetchUsersInfo()
            print("User info fetch successful")
            
            
            totalRoster = info.totalRosters
            name = info.name
            season = info.season
            users = userInfo
            
            print(users)
            print(totalRoster)
            print(name)

        }
        catch {
            
        }
    }
    
    
}
