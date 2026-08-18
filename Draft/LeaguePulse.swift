//
//  LeaguePulse.swift
//  Draft
//
//  Created by John Chavez on 8/17/26.
//

import SwiftUI

struct LeaguePulseRow: Identifiable {
    var id: String
    var title: String
    var detail: String
    var systemImage: String
}

enum LeagueWeekPulse {
    static func rows(
        users: [UsersAndMatchups],
        players: [String: PlayersInfo],
        week: Int
    ) -> [LeaguePulseRow] {
        let paired = users.filter { $0.matchups.matchupID != 0 }
        var rows: [LeaguePulseRow] = []

        if let high = paired.max(by: { $0.matchups.points < $1.matchups.points }),
           high.matchups.points > 0 {
            rows.append(
                LeaguePulseRow(
                    id: "high-team",
                    title: "Highest score",
                    detail: "\(high.usersAndRosters.user.metaData.teamName) · \(DraftFormat.points(high.matchups.points))",
                    systemImage: "arrow.up.right"
                )
            )
            if let low = paired.min(by: { $0.matchups.points < $1.matchups.points }),
               low.usersAndRosters.userGameWinLossTie.rosterID != high.usersAndRosters.userGameWinLossTie.rosterID {
                rows.append(
                    LeaguePulseRow(
                        id: "low-team",
                        title: "Lowest score",
                        detail: "\(low.usersAndRosters.user.metaData.teamName) · \(DraftFormat.points(low.matchups.points))",
                        systemImage: "arrow.down.right"
                    )
                )
            }
        }

        let playerScores = scoredPlayers(in: users, players: players)
        if let best = playerScores.max(by: { $0.points < $1.points }) {
            rows.append(
                LeaguePulseRow(
                    id: "high-player",
                    title: "Best player",
                    detail: "\(best.name) · \(DraftFormat.points(best.points)) (\(best.teamName))",
                    systemImage: "star"
                )
            )
        }
        if let quiet = playerScores.min(by: { $0.points < $1.points }), playerScores.count > 1 {
            rows.append(
                LeaguePulseRow(
                    id: "low-player",
                    title: "Quietest player",
                    detail: "\(quiet.name) · \(DraftFormat.points(quiet.points)) (\(quiet.teamName))",
                    systemImage: "moon.stars"
                )
            )
        }

        if let closest = closestPair(in: paired) {
            rows.append(
                LeaguePulseRow(
                    id: "closest",
                    title: "Closest matchup",
                    detail: closest,
                    systemImage: "arrow.left.arrow.right"
                )
            )
        }

        let injuries = injuredPlayers(in: users, players: players).prefix(3)
        for injury in injuries {
            rows.append(
                LeaguePulseRow(
                    id: "injury-\(injury.id)",
                    title: injury.status,
                    detail: "\(injury.name) · \(injury.teamName)",
                    systemImage: "cross.case"
                )
            )
        }

        if rows.isEmpty {
            rows.append(
                LeaguePulseRow(
                    id: "empty",
                    title: "Week \(week)",
                    detail: "Scoring and injuries show up here once the week starts.",
                    systemImage: "sportscourt"
                )
            )
        }

        return rows
    }

    private struct PlayerScore {
        var id: String
        var name: String
        var teamName: String
        var points: Float
    }

    private struct InjuryNote {
        var id: String
        var name: String
        var teamName: String
        var status: String
    }

    private static func scoredPlayers(
        in users: [UsersAndMatchups],
        players: [String: PlayersInfo]
    ) -> [PlayerScore] {
        var seen = Set<String>()
        var scores: [PlayerScore] = []
        for user in users {
            let teamName = user.usersAndRosters.user.metaData.teamName
            let starters = Set(user.usersAndRosters.userGameWinLossTie.starters.filter { $0 != "0" && !$0.isEmpty })
            for (playerID, points) in user.matchups.playerPoints where points > 0 {
                if !starters.isEmpty && !starters.contains(playerID) {
                    continue
                }
                guard seen.insert(playerID).inserted else { continue }
                let player = players[playerID]
                scores.append(
                    PlayerScore(
                        id: playerID,
                        name: player?.displayName ?? playerID,
                        teamName: teamName,
                        points: points
                    )
                )
            }
        }
        return scores
    }

    private static func closestPair(in users: [UsersAndMatchups]) -> String? {
        var seen = Set<Int>()
        var best: (margin: Float, text: String)?
        for user in users {
            let matchupID = user.matchups.matchupID
            guard matchupID != 0, seen.insert(matchupID).inserted else { continue }
            guard let opponent = users.first(where: {
                $0.matchups.matchupID == matchupID
                    && $0.usersAndRosters.userGameWinLossTie.rosterID != user.usersAndRosters.userGameWinLossTie.rosterID
            }) else { continue }
            guard user.matchups.points > 0 || opponent.matchups.points > 0 else { continue }
            let margin = abs(user.matchups.points - opponent.matchups.points)
            let text = "\(user.usersAndRosters.user.metaData.teamName) \(DraftFormat.points(user.matchups.points))–\(DraftFormat.points(opponent.matchups.points)) \(opponent.usersAndRosters.user.metaData.teamName)"
            if best == nil || margin < best!.margin {
                best = (margin, text)
            }
        }
        return best?.text
    }

    private static func injuredPlayers(
        in users: [UsersAndMatchups],
        players: [String: PlayersInfo]
    ) -> [InjuryNote] {
        var seen = Set<String>()
        var notes: [InjuryNote] = []
        for user in users {
            for playerID in user.usersAndRosters.userGameWinLossTie.players {
                guard seen.insert(playerID).inserted, let player = players[playerID] else { continue }
                guard !player.injuryStatus.isEmpty else { continue }
                notes.append(
                    InjuryNote(
                        id: playerID,
                        name: player.displayName,
                        teamName: user.usersAndRosters.user.metaData.teamName,
                        status: player.injuryStatus
                    )
                )
            }
        }
        return notes
    }
}

struct LeaguePulseSection: View {
    var rows: [LeaguePulseRow]
    var header: String = "This week"

    var body: some View {
        Section(header) {
            ForEach(rows) { row in
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(row.title)
                            .font(.subheadline.weight(.semibold))
                        Text(row.detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } icon: {
                    Image(systemName: row.systemImage)
                        .foregroundStyle(.tint)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(row.title), \(row.detail)")
            }
        }
    }
}

struct LeagueFeedView: View {
    var users: [UsersAndMatchups]
    var week: Int
    var players: [String: PlayersInfo]
    var leagueName: String

    @State private var nflGames: [NFLGame] = []

    private var rows: [LeaguePulseRow] {
        LeagueWeekPulse.rows(users: users, players: players, week: week)
    }

    var body: some View {
        List {
            if !nflGames.isEmpty {
                Section {
                    NFLScoreBanner(games: nflGames)
                        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                } header: {
                    Text("NFL")
                }
            }

            LeaguePulseSection(rows: rows, header: "Week \(week)")
        }
        .listStyle(.insetGrouped)
        .navigationTitle(leagueName.isEmpty ? "Feed" : leagueName)
        .navigationBarTitleDisplayMode(.large)
        .navigationSubtitle("Week \(week)")
        .accessibilityLabel("League feed, week \(week)")
        .refreshable {
            await loadScoreboard(force: true)
        }
        .task {
            await loadScoreboard()
        }
    }

    private func loadScoreboard(force: Bool = false) async {
        nflGames = await NFLScoreboard.fetch(force: force)
    }
}
