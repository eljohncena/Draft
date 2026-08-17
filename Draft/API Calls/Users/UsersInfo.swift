//
//  UsersInfo.swift
//  Draft
//
//  Created by John Chavez on 9/10/23.
//

import Foundation
import SwiftUI

struct UsersInfo: Decodable, Identifiable, Hashable {
    static func == (lhs: UsersInfo, rhs: UsersInfo) -> Bool {
        return lhs.userID == rhs.userID && lhs.avatarImage == rhs.avatarImage && lhs.metaData == rhs.metaData && lhs.displayName == rhs.displayName && lhs.sleeperAvatarID == rhs.sleeperAvatarID
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(userID)
        hasher.combine(metaData)
        hasher.combine(displayName)
        hasher.combine(sleeperAvatarID)
    }

    var userID: String = ""
    var metaData: MetaData
    var displayName: String = ""
    var sleeperAvatarID: String = ""
    var avatarImage: UIImage?
    var id = UUID()

    var displayAvatar: UIImage {
        avatarImage ?? AvatarCache.placeholder(displayName)
    }

    struct MetaData: Decodable, Hashable {
        var teamName: String = ""
        var avatarURL: String = ""
    }

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case displayName = "display_name"
        case sleeperAvatarID = "avatar"
        case metaData = "metadata"

        enum MetaDataCodingKeys: String, CodingKey {
            case teamName = "team_name"
            case avatarURL = "avatar"
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userID = try container.decode(String.self, forKey: .userID)
        displayName = try container.decode(String.self, forKey: .displayName)
        sleeperAvatarID = try container.decodeIfPresent(String.self, forKey: .sleeperAvatarID) ?? ""

        guard let metaDataContainer = try? container.nestedContainer(keyedBy: CodingKeys.MetaDataCodingKeys.self, forKey: .metaData) else {
            metaData = MetaData(teamName: displayName, avatarURL: "")
            return
        }

        let teamName = try metaDataContainer.decodeIfPresent(String.self, forKey: .teamName) ?? displayName
        let avatarURL = try metaDataContainer.decodeIfPresent(String.self, forKey: .avatarURL) ?? ""
        metaData = MetaData(teamName: teamName, avatarURL: avatarURL)
    }
}

extension UsersInfo {
    init(userID: String, displayName: String, avatarImage: UIImage?, metaData: MetaData, sleeperAvatarID: String = "") {
        self.userID = userID
        self.displayName = displayName
        self.avatarImage = avatarImage
        self.metaData = metaData
        self.sleeperAvatarID = sleeperAvatarID
    }
}
