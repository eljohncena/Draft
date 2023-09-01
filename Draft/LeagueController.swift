//
//  LeagueController.swift
//  Draft
//
//  Created by John Chavez on 8/31/23.
//

import Foundation
import UIKit

class LeagueController {
    
    enum LeagueControllerError: Error, LocalizedError {
        case itemNotFound
    }
    
    func fetchLeagueInfo() async throws -> LeagueInfo {
        
        var urlComponents = URLComponents(string: "https://api.sleeper.app/v1/league/<league_id>")!
        
        let (data,response) = try await URLSession.shared.data(from: urlComponents.url!)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw LeagueControllerError.itemNotFound
        }
        
        let jsonDecoder = JSONDecoder()
        let leagueInfo = try jsonDecoder.decode(LeagueInfo.self, from: data)
        return (leagueInfo)
    }
    
}
