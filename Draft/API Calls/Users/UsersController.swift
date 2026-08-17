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
        try await SleeperClient.get("league/\(SleeperConfig.leagueID)/users")
    }

    func fetchAvatar(for user: UsersInfo) async -> UIImage {
        await AvatarCache.image(
            customURL: user.metaData.avatarURL,
            sleeperID: user.sleeperAvatarID,
            displayName: user.displayName
        )
    }
}
