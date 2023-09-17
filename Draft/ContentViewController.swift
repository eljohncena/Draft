//
//  ContentViewController.swift
//  test
//
//  Created by John Chavez on 9/9/23.
//

import Foundation
import SwiftUI

@MainActor
class ContentViewController: ObservableObject{
    let leagueController = LeagueController()
    let userController = UsersController()
    let rosterController = RostersController()
    let matchupController = MatchupsController()
    
    @Published var name = ""
    @Published var totalRoster = 0
    @Published var season = ""
    @Published var users: [UsersInfo] = []
    @Published var rosters: [RostersInfo] = []
    @Published var week: Int = 0
    
    @Published var usersWithInfo:[UsersWithInfo] = []
    @Published var matchups: [MatchupsInfo] = []
    @Published var usersAndRosters: [UsersAndMatchups] = []
    
    enum ViewControllerError: Error {
        case localizedError
        case fetchFailed
    }
    
    func startProcess() async {
        
        var info:LeagueInfo
        var userInfo: [UsersInfo]
        var rosterInfo: [RostersInfo]
        
        
        do {
            
            info = try await leagueController.fetchLeagueInfo()
            
            DispatchQueue.main.async {
                self.totalRoster = info.totalRosters
                self.name = info.name
                self.season = info.season
                self.week = info.settings.leg
            }
            
            print("League info process and decode successful")
            
            do {
                let matchupsInfo = try await matchupController.fetchMatchupsInfo(week: info.settings.leg)
                DispatchQueue.main.async {
                    self.matchups = matchupsInfo
                    
                }
            } catch {
                print("Matchups info process failes \(ViewControllerError.localizedError)")
            }
            
            
            print("User Matchup process and decode successful")
            
            
        } catch {
            print("League info process failed: \(ViewControllerError.localizedError)")
        }

        
        do {
            
            userInfo = try await userController.fetchUsersInfo()
            
            DispatchQueue.main.async {
                self.users = userInfo
                
            }
            
            
        } catch {
            
            print("User info process failed \(ViewControllerError.localizedError)")
        }
        print("User info process and decode successful")
        
        do {
            
            rosterInfo = try await rosterController.fetchRostersInfo()
            DispatchQueue.main.async {
                self.rosters = rosterInfo
            }
            
            
        } catch {
            print("Roster info process failed: \(ViewControllerError.localizedError)")
        }
        print("Roster Roster process and decode successful")
        
    }

    
    func combineUsersAndRosters() -> [UsersWithInfo] {
        return self.users.map { user in
            guard let userStatistics = self.rosters.first(where: { $0.userID == user.userID }) else {
                let rosterInfoSettings = RostersInfo.Settings(wins: 0, ties: 0, losses: 0)
                let defaultRostersInfo = RostersInfo(settings: rosterInfoSettings ,rosterID: 0, userID: "")
                print("CombineUsersAndRoster func Failed")
                return UsersWithInfo(user: user, userGameWinLossTie: defaultRostersInfo)

            }
            print("CombineUsersAndRoster func success")
            return UsersWithInfo(user: user, userGameWinLossTie: userStatistics)
        }
    }

    func combineUsersAndMatchups(usersAndRosters: [UsersWithInfo]) -> [UsersAndMatchups] {
        return usersAndRosters.map { user in
            guard let userStatistics = self.matchups.first(where: { $0.rosterID == user.userGameWinLossTie.rosterID }) else {

                let defaultUsersWithInfo = UsersWithInfo(user: user.user, userGameWinLossTie: user.userGameWinLossTie)
                print("combineUsersAndMatchups func Failed")
                return UsersAndMatchups(usersAndRosters: defaultUsersWithInfo, matchups: MatchupsInfo(rosterID: 0, points: 0, matchupID: 0))

                    }
            print("combineUsersAndMatchups func success")
            return UsersAndMatchups(usersAndRosters: user, matchups: userStatistics)
                }
            }

}

