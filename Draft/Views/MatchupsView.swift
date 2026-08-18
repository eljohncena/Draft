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
    var currentWeek: Int

    @ObservedObject private var ballot = MatchupBallot.shared

    private var scoringHasStarted: Bool {
        users.contains { $0.matchups.points > 0 }
    }

    private var votesLocked: Bool {
        !GameDay.canChangeMatchupVote(
            selectedWeek: week,
            currentWeek: currentWeek,
            scoringHasStarted: scoringHasStarted
        )
    }

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
                    teamSide(user, opponent: nil, tally: nil)
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .draftGlass(in: RoundedRectangle(cornerRadius: 24, style: .continuous))
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
        let tally: MatchupBallot.Tally? = opponent.map {
            ballot.tally(
                week: week,
                matchupID: user.matchups.matchupID,
                leftUserID: user.usersAndRosters.user.userID,
                rightUserID: $0.usersAndRosters.user.userID
            )
        }

        return VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 8) {
                teamSide(user, opponent: opponent, tally: tally)
                Text("VS")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.top, 20)
                    .accessibilityHidden(true)
                if let opponent {
                    teamSide(opponent, opponent: user, tally: tally)
                }
            }

            if let tally {
                Text(voteStatusText(tally))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(voteStatusText(tally))
            }
        }
        .padding(16)
        .draftGlass(in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func teamSide(_ user: UsersAndMatchups, opponent: UsersAndMatchups?, tally: MatchupBallot.Tally?) -> some View {
        let settings = user.usersAndRosters.userGameWinLossTie.settings
        let userID = user.usersAndRosters.user.userID
        let percent = tally?.percent(for: userID)

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

            if let tally, opponent != nil {
                Text(percent.map { "\($0)%" } ?? "—")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(percent == nil ? Color.secondary : Color.primary)
                    .accessibilityLabel(percent.map { "\($0) percent pick this team to win" } ?? "No votes yet")

                MatchupVoteButtons(
                    teamName: user.usersAndRosters.user.metaData.teamName,
                    opponentName: opponent?.usersAndRosters.user.metaData.teamName ?? "opponent",
                    pickedThisTeam: tally.myWinnerUserID == userID,
                    pickedOpponent: tally.myWinnerUserID != nil && tally.myWinnerUserID != userID,
                    locked: votesLocked,
                    onUp: {
                        ballot.cast(
                            week: week,
                            matchupID: user.matchups.matchupID,
                            winnerUserID: userID,
                            locked: votesLocked
                        )
                    },
                    onDown: {
                        if let opponent {
                            ballot.cast(
                                week: week,
                                matchupID: user.matchups.matchupID,
                                winnerUserID: opponent.usersAndRosters.user.userID,
                                locked: votesLocked
                            )
                        }
                    }
                )
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func voteStatusText(_ tally: MatchupBallot.Tally) -> String {
        let count = tally.total == 0
            ? "No votes yet"
            : (tally.total == 1 ? "1 vote" : "\(tally.total) votes")
        if votesLocked {
            return tally.total == 0 ? "Voting locked" : "\(count) · locked"
        }
        if tally.hasVoted {
            return "\(count) · change until kickoff"
        }
        return count
    }
}

private struct MatchupVoteButtons: View {
    let teamName: String
    let opponentName: String
    let pickedThisTeam: Bool
    let pickedOpponent: Bool
    let locked: Bool
    let onUp: () -> Void
    let onDown: () -> Void

    @State private var voteTick = 0

    var body: some View {
        HStack(spacing: 8) {
            voteButton(
                systemName: pickedThisTeam ? "hand.thumbsup.fill" : "hand.thumbsup",
                selected: pickedThisTeam,
                action: onUp,
                label: "Vote for \(teamName) to win",
                hint: locked
                    ? "Voting is locked after kickoff"
                    : "Picks \(teamName) to win. You can change this until kickoff."
            )
            voteButton(
                systemName: pickedOpponent ? "hand.thumbsdown.fill" : "hand.thumbsdown",
                selected: pickedOpponent,
                action: onDown,
                label: "Vote against \(teamName), for \(opponentName)",
                hint: locked
                    ? "Voting is locked after kickoff"
                    : "Picks \(opponentName) to win. You can change this until kickoff."
            )
        }
        .sensoryFeedback(.impact(flexibility: .solid, intensity: 0.7), trigger: voteTick)
    }

    private func voteButton(
        systemName: String,
        selected: Bool,
        action: @escaping () -> Void,
        label: String,
        hint: String
    ) -> some View {
        Button {
            action()
            if !locked {
                voteTick += 1
            }
        } label: {
            Image(systemName: systemName)
                .imageScale(.medium)
                .frame(minWidth: 28, minHeight: 22)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .tint(selected ? Color.accentColor : Color.secondary)
        .disabled(locked)
        .accessibilityLabel(label)
        .accessibilityHint(hint)
        .accessibilityAddTraits(selected ? .isSelected : [])
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
            MatchupsView(users: combinedUserInfo, week: 1, currentWeek: 1)
        }
    }
}
