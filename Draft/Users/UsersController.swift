//
//  UserController.swift
//  Draft
//
//  Created by John Chavez on 9/10/23.
//

import Foundation
import SwiftUI

class UsersController {
    
    enum UsersControllerError: Error, LocalizedError {
        case itemNotFound
        case decodingFailed
    }
    
    func fetchUsersInfo() async throws -> [UsersInfo] {
        
        let urlComponents = URLComponents(string: "https://api.sleeper.app/v1/league/989252508654567424/users")!
        
        let (data,response) = try await URLSession.shared.data(from: urlComponents.url!)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw UsersControllerError.itemNotFound
        }
        
        let decodedResponse = try JSONDecoder().decode([UsersInfo].self, from: data)
        print("JSON Users retreival successful")
        return decodedResponse
        
    }
    
}
