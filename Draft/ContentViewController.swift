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

    @Published var name = ""
    @Published var totalRoster = 0
    @Published var season = ""
    @Published var users: [UsersInfo] = []
    @Published var rosters: [RostersInfo] = []
    
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
            }


        } catch {
            print("League info process failed: \(ViewControllerError.localizedError)")
            }

            print("League info process and decode successful")

        do {

            userInfo = try await userController.fetchUsersInfo()

            DispatchQueue.main.async {
                self.users = userInfo

            }


        } catch {

            print("User info process failed \(ViewControllerError.localizedError)")
        }

        do {

            rosterInfo = try await rosterController.fetchRostersInfo()
            DispatchQueue.main.async {
                self.rosters = rosterInfo
            }


        } catch {
            print("Roster info process failed: \(ViewControllerError.localizedError)")
            }


            print("User info process and decode successful")

            print(users)
            print(totalRoster)
            print(name)

        }
}
