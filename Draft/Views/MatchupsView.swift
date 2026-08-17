//
//  MatchupsView.swift
//  Draft
//
//  Created by John Chavez on 9/17/23.
//

import SwiftUI

struct MatchupsView: View {

    var users: [UsersAndMatchups]
    var week: Int

    private var uniquePairings: [UsersAndMatchups] {
        var seenMatchupIDs = Set<Int>()
        return users.sorted { $0.matchups.points > $1.matchups.points }.filter { user in
            user.matchups.matchupID != 0 && seenMatchupIDs.insert(user.matchups.matchupID).inserted
        }
    }

    private var unmatchedTeams: [UsersAndMatchups] {
        users.filter { $0.matchups.matchupID == 0 }
    }

    private func opponent(for user: UsersAndMatchups) -> UsersAndMatchups? {
        users.first {
            $0.matchups.matchupID == user.matchups.matchupID
                && $0.usersAndRosters.userGameWinLossTie.rosterID != user.usersAndRosters.userGameWinLossTie.rosterID
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(uniquePairings) { user in
                    pairingCard(user, opponent: opponent(for: user))
                }

                ForEach(unmatchedTeams) { user in
                    teamSide(user)
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .navigationTitle("Matchups")
        .navigationBarTitleDisplayMode(.large)
        .navigationSubtitle("Week \(week)")
    }

    private func pairingCard(_ user: UsersAndMatchups, opponent: UsersAndMatchups?) -> some View {
        HStack(alignment: .center, spacing: 8) {
            teamSide(user)
            Text("VS")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .accessibilityHidden(true)
            if let opponent {
                teamSide(opponent)
            }
        }
        .padding(16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(pairingLabel(user, opponent: opponent))
    }

    private func pairingLabel(_ user: UsersAndMatchups, opponent: UsersAndMatchups?) -> String {
        let left = "\(user.usersAndRosters.user.metaData.teamName) \(DraftFormat.points(user.matchups.points))"
        guard let opponent else {
            return left
        }
        return "\(left) versus \(opponent.usersAndRosters.user.metaData.teamName) \(DraftFormat.points(opponent.matchups.points))"
    }

    private func teamSide(_ user: UsersAndMatchups) -> some View {
        let settings = user.usersAndRosters.userGameWinLossTie.settings
        return VStack(spacing: 8) {
            TeamAvatar(image: user.usersAndRosters.user.displayAvatar, size: 52)
            Text(user.usersAndRosters.user.metaData.teamName)
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
            Text(DraftFormat.record(wins: settings.wins, ties: settings.ties, losses: settings.losses))
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(DraftFormat.points(user.matchups.points))
                .font(.title3.weight(.semibold).monospacedDigit())
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }
}

struct MatchupsView_Previews: PreviewProvider {
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
            ),
            UsersAndMatchups(
                usersAndRosters: UsersWithInfo(
                    user: UsersInfo(
                        userID: "12345",
                        displayName: "Patriots",
                        avatarImage: UIImage(systemName: "questionmark"),
                        metaData: UsersInfo.MetaData(teamName: "NotPatriotsBecauseBrady", avatarURL: "")
                    ),
                    userGameWinLossTie: RostersInfo(settings: RostersInfo.Settings(), rosterID: 2, userID: "23")
                ),
                matchups: MatchupsInfo(rosterID: 2, points: 89.0, matchupID: 1)
            )
        ]

        return NavigationStack {
            MatchupsView(users: combinedUserInfo, week: 1)
        }
    }
}
