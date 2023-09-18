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
            print("Failed to fetch JSON User")
            throw UsersControllerError.itemNotFound
            }
        
        print(httpResponse.statusCode)
        
//        case 200: print("All Clear")
//        case 400: print("Bad Request -- Your request is Invalid")
//        case 404: print("Too Many Requests -- You're requesting too mauch")
//        case 500: print("Internal Server Error")
//        case 503: print("Service unavailable; offline for maintenance")
        
        var decodedResponse:[UsersInfo] = []
        do {
            
            decodedResponse = try JSONDecoder().decode([UsersInfo].self, from: data)
            return decodedResponse
        }
        catch {
            print(error)
        }

        print("JSON Users decode successful")
        return decodedResponse
        
        
    }
    
    func fetchAvatar(from avatarURL: String) async throws -> UIImage {
        do{
            let urlComponents = URLComponents(string: avatarURL)!
            
            let (data,response) = try await URLSession.shared.data(from: urlComponents.url!)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Failed to fetch User avatar")
                throw UsersControllerError.itemNotFound
            }
            
            print(httpResponse.statusCode)
            
            guard let image = UIImage(data: data) else {
                return UIImage(systemName: "questionmark")! }
            
            print("Fetch User avatar successful")
            return image
            
        } catch {
            print(UsersControllerError.itemNotFound)
            return UIImage(systemName: "questionmark")!
        }
    }
}
