//
//  LeagueSnapshot.swift
//  Draft
//
//  Created by John Chavez on 8/17/26.
//

import Foundation

struct LeagueSnapshot {
    var leagueID: String
    var name: String
    var season: String
    var week: Int
    var totalRosters: Int
    var users: [UsersInfo]
    var rosters: [RostersInfo]
    var matchupsByWeek: [Int: [MatchupsInfo]]

    var currentMatchups: [MatchupsInfo] {
        matchupsByWeek[week] ?? []
    }
}

extension RankWidgetSnapshot {
    static func make(from snapshot: LeagueSnapshot) -> RankWidgetSnapshot {
        let week = max(snapshot.week, 1)
        let rows: [(team: Team, weekPoints: Float)] = snapshot.users.compactMap { user in
            guard let roster = snapshot.rosters.first(where: { $0.userID == user.userID }) else {
                return nil
            }
            let record = WeekRecord.through(
                week: week,
                rosterID: roster.rosterID,
                matchupsByWeek: snapshot.matchupsByWeek
            )
            let matchup = snapshot.matchupsByWeek[week]?.first(where: { $0.rosterID == roster.rosterID })
            let teamName = user.metaData.teamName.isEmpty ? user.displayName : user.metaData.teamName
            return (
                Team(
                    userID: user.userID,
                    rosterID: roster.rosterID,
                    teamName: teamName,
                    displayName: user.displayName,
                    rank: 0,
                    wins: record.wins,
                    ties: record.ties,
                    losses: record.losses,
                    pointsFor: record.pointsFor,
                    weekPoints: Double(matchup?.points ?? 0),
                    matchupID: matchup?.matchupID ?? 0,
                    opponentUserID: nil
                ),
                matchup?.points ?? 0
            )
        }

        let ranked = rows.sorted { lhs, rhs in
            if lhs.team.wins != rhs.team.wins {
                return lhs.team.wins > rhs.team.wins
            }
            if lhs.team.pointsFor != rhs.team.pointsFor {
                return lhs.team.pointsFor > rhs.team.pointsFor
            }
            return lhs.weekPoints > rhs.weekPoints
        }

        var teams = ranked.enumerated().map { index, row -> Team in
            var team = row.team
            team.rank = index + 1
            return team
        }

        for index in teams.indices where teams[index].matchupID != 0 {
            let matchupID = teams[index].matchupID
            let userID = teams[index].userID
            teams[index].opponentUserID = teams.first {
                $0.matchupID == matchupID && $0.userID != userID
            }?.userID
        }

        return RankWidgetSnapshot(
            leagueID: snapshot.leagueID,
            leagueName: snapshot.name,
            season: snapshot.season,
            week: week,
            teams: teams,
            updatedAt: Date()
        )
    }
}
