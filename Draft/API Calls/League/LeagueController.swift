//
//  LeagueController.swift
//  test
//
//  Created by John Chavez on 9/9/23.
//

import Foundation
import SwiftUI

class LeagueController {

    enum LeagueControllerError: Error, LocalizedError {
        case itemNotFound
        case decodingFailed
    }
    
    func fetchLeagueInfo() async throws -> LeagueInfo {

        let urlComponents = URLComponents(string: "https://api.sleeper.app/v1/league/989252508654567424")!

        let (data,response) = try await URLSession.shared.data(from: urlComponents.url!)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            print("Failed to fetch JSON League")
            throw LeagueControllerError.itemNotFound
        }

        print(httpResponse.statusCode)
        
//        case 200: print("All Clear")
//        case 400: print("Bad Request -- Your request is Invalid")
//        case 404: print("Too Many Requests -- You're requesting too mauch")
//        case 500: print("Internal Server Error")
//        case 503: print("Service unavailable; offline for maintenance")
        
        var decodedResponse: LeagueInfo?
        do {
            decodedResponse = try JSONDecoder().decode(LeagueInfo.self, from: data)
        }
        catch {
            print(error)
        }
        print("JSON League decode successful")
        return decodedResponse!
    }
    
}
