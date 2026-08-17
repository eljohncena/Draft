//
//  WeeklyStandingsView.swift
//  Draft
//
//  Created by John Chavez on 9/19/23.
//

import SwiftUI

struct WeeklyStandingsView: View {

    var users: [UsersAndMatchups]
    var week: Int
    @AppStorage("sleeperMyUserID", store: AppGroup.defaults) private var myUserID = ""

    private var rankedUsers: [UsersAndMatchups] {
        users.sorted { lhs, rhs in
            if lhs.weekRecord.wins != rhs.weekRecord.wins {
                return lhs.weekRecord.wins > rhs.weekRecord.wins
            }
            if lhs.weekRecord.pointsFor != rhs.weekRecord.pointsFor {
                return lhs.weekRecord.pointsFor > rhs.weekRecord.pointsFor
            }
            return lhs.matchups.points > rhs.matchups.points
        }
    }

    var body: some View {
        List {
            ForEach(Array(rankedUsers.enumerated()), id: \.element.id) { index, user in
                NavigationLink(value: user) {
                    TeamStandingsRow(
                        user: user,
                        rank: index + 1,
                        week: week,
                        isMine: user.usersAndRosters.user.userID == myUserID
                    )
                }
                .contextMenu {
                    Button("That’s me") {
                        SleeperConfig.rememberMe(
                            userID: user.usersAndRosters.user.userID,
                            displayName: user.usersAndRosters.user.metaData.teamName
                        )
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .id(week)
        .navigationSubtitle("Week \(week)")
        .accessibilityLabel("Standings, week \(week)")
    }
}

struct WeeklyStandingsView_Previews: PreviewProvider {
    static var previews: some View {
        let combinedUserInfo = [
            UsersAndMatchups(
                usersAndRosters: UsersWithInfo(
                    user: UsersInfo(
                        userID: "98782",
                        displayName: "NotGreenBay",
                        avatarImage: UIImage(systemName: "questionmark"),
                        metaData: UsersInfo.MetaData(teamName: "NotGreenBay", avatarURL: "")
                    ),
                    userGameWinLossTie: RostersInfo(settings: RostersInfo.Settings(), rosterID: 1, userID: "23")
                ),
                matchups: MatchupsInfo(rosterID: 1, points: 100.0, matchupID: 1)
            )
        ]

        return NavigationStack {
            WeeklyStandingsView(users: combinedUserInfo, week: 1)
        }
    }
}
