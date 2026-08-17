//
//  RosterController.swift
//  Draft
//
//  Created by John Chavez on 9/10/23.
//

import Foundation

class RostersController {

    enum RostersControllerError: Error, LocalizedError {
        case itemNotFound
        case decodingFailed
    }

    func fetchRostersInfo() async throws -> [RostersInfo] {
        try await SleeperClient.get("league/\(SleeperConfig.leagueID)/rosters")
    }
}
