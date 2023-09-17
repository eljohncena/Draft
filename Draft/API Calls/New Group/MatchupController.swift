//
//  MatchupController.swift
//  Draft
//
//  Created by John Chavez on 9/12/23.
//

import Foundation
import SwiftUI

class MatchupsController {
    
    enum MatchupsControllerError: Error, LocalizedError {
        case itemNotFound
        case decodingFailed
        
    }
    
    func fetchMatchupsInfo(week: Int) async throws -> [MatchupsInfo] {
        
        let urlComponents = URLComponents(string: "https://api.sleeper.app/v1/league/989252508654567424/matchups/\(week)")!
        
        let (data,response) = try await URLSession.shared.data(from: urlComponents.url!)
        
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            print("Failed to fetch Matchups")
            throw MatchupsControllerError.itemNotFound
            }
        
        print(httpResponse.statusCode)
        
//        case 200: print("All Clear")
//        case 400: print("Bad Request -- Your request is Invalid")
//        case 404: print("Too Many Requests -- You're requesting too mauch")
//        case 500: print("Internal Server Error")
//        case 503: print("Service unavailable; offline for maintenance")
        
        var decodedResponse:[MatchupsInfo] = []
        do {
            
            decodedResponse = try JSONDecoder().decode([MatchupsInfo].self, from: data)
            return decodedResponse
        }
        catch {
            print(error)
            print("Failed to Decode in MatchupController")
        }

        print("JSON Matchups decode successful")
        return decodedResponse
        
    }

    
}
