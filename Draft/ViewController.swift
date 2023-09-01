//
//  ViewController.swift
//  Draft
//
//  Created by John Chavez on 8/31/23.
//

import Foundation
import SwiftUI

class ViewController: ObservableObject {
    
    let leagueController = LeagueController()
    
    
    func startProcess () async {
        do {
            let leagueInfo = try await leagueController.fetchLeagueInfo()
            await updateUI(with: leagueInfo)
        }
        catch{
            updateUI(with: error)
        }
    }
    
    func updateUI(with leagueInfo: LeagueInfo) async {
        do {
            
        }
        catch {
            updateUI(with: error)
        }
    }
    
    func updateUI(with error: Error) {
        
    }
}
