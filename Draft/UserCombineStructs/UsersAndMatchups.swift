//
//  UsersAndMatchups.swift
//  Draft
//
//  Created by John Chavez on 9/12/23.
//

import Foundation

struct WeekRecord: Hashable {
    var wins: Int = 0
    var ties: Int = 0
    var losses: Int = 0
    var pointsFor: Double = 0

    static func through(week: Int, rosterID: Int, matchupsByWeek: [Int: [MatchupsInfo]]) -> WeekRecord {
        var record = WeekRecord()
        guard week >= 1 else { return record }

        for weekNumber in 1...week {
            guard let weekMatchups = matchupsByWeek[weekNumber],
                  let mine = weekMatchups.first(where: { $0.rosterID == rosterID }) else {
                continue
            }

            record.pointsFor += Double(mine.points)

            guard mine.matchupID != 0,
                  let opponent = weekMatchups.first(where: {
                      $0.matchupID == mine.matchupID && $0.rosterID != rosterID
                  }) else {
                continue
            }

            if mine.points == 0 && opponent.points == 0 {
                continue
            }

            if mine.points > opponent.points {
                record.wins += 1
            } else if mine.points < opponent.points {
                record.losses += 1
            } else {
                record.ties += 1
            }
        }

        return record
    }
}

struct UsersAndMatchups: Identifiable, Hashable {
    static func == (lhs: UsersAndMatchups, rhs: UsersAndMatchups) -> Bool {
        lhs.usersAndRosters == rhs.usersAndRosters
            && lhs.matchups == rhs.matchups
            && lhs.weekRecord == rhs.weekRecord
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(usersAndRosters)
        hasher.combine(matchups)
        hasher.combine(weekRecord)
    }

    var usersAndRosters: UsersWithInfo
    var matchups: MatchupsInfo
    var weekRecord: WeekRecord

    var id: String {
        "\(usersAndRosters.userGameWinLossTie.rosterID)-\(usersAndRosters.user.userID)"
    }

    init(usersAndRosters: UsersWithInfo, matchups: MatchupsInfo, weekRecord: WeekRecord? = nil) {
        self.usersAndRosters = usersAndRosters
        self.matchups = matchups
        if let weekRecord {
            self.weekRecord = weekRecord
        } else {
            let settings = usersAndRosters.userGameWinLossTie.settings
            self.weekRecord = WeekRecord(
                wins: settings.wins,
                ties: settings.ties,
                losses: settings.losses,
                pointsFor: settings.totalPoints
            )
        }
    }
}

