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
            throw LeagueControllerError.itemNotFound
        }

        let decodedResponse = try JSONDecoder().decode(LeagueInfo.self, from: data)
        print("JSON League retreival successful")
        return decodedResponse

    }


}
