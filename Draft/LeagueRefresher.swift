//
//  LeagueRefresher.swift
//  Draft
//
//  Created by John Chavez on 8/17/26.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

enum LeagueRefresher {
    static func fetch(includeAvatars: Bool) async throws -> LeagueSnapshot {
        let leagueController = LeagueController()
        let userController = UsersController()
        let rosterController = RostersController()
        let matchupController = MatchupsController()

        let info = try await leagueController.fetchLeagueInfo()

        var matchupsByWeek: [Int: [MatchupsInfo]] = [:]
        if let matchups = try? await matchupController.fetchMatchupsInfo(week: info.settings.leg) {
            matchupsByWeek[info.settings.leg] = matchups
        }

        var users = (try? await userController.fetchUsersInfo()) ?? []
        if includeAvatars {
            #if canImport(UIKit)
            await withTaskGroup(of: (Int, UIImage).self) { group in
                for index in users.indices {
                    let user = users[index]
                    group.addTask {
                        let image = await AvatarCache.image(
                            customURL: user.metaData.avatarURL,
                            sleeperID: user.sleeperAvatarID,
                            displayName: user.displayName
                        )
                        return (index, image)
                    }
                }
                for await (index, image) in group {
                    users[index].avatarImage = image
                }
            }
            #endif
        }

        let rosters = (try? await rosterController.fetchRostersInfo()) ?? []

        return LeagueSnapshot(
            leagueID: SleeperConfig.leagueID,
            name: info.name,
            season: info.season,
            week: info.settings.leg,
            totalRosters: info.totalRosters,
            users: users,
            rosters: rosters,
            matchupsByWeek: matchupsByWeek
        )
    }

    static func publish(_ snapshot: LeagueSnapshot) {
        RankWidgetCache.write(RankWidgetSnapshot.make(from: snapshot))
    }
}
