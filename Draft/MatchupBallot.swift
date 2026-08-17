//
//  MatchupBallot.swift
//  Draft
//
//  Created by John Chavez on 8/17/26.
//

import Combine
import Foundation

@MainActor
final class MatchupBallot: ObservableObject {
    static let shared = MatchupBallot()

    struct Vote: Codable, Hashable, Identifiable {
        var leagueID: String
        var week: Int
        var matchupID: Int
        var voterID: String
        var winnerUserID: String

        var id: String {
            "\(leagueID)|\(week)|\(matchupID)|\(voterID)"
        }
    }

    struct Tally {
        var total: Int
        var myWinnerUserID: String?

        private var leftCount: Int
        private var leftUserID: String
        private var rightUserID: String

        init(votes: [Vote], leftUserID: String, rightUserID: String, voterID: String) {
            self.leftUserID = leftUserID
            self.rightUserID = rightUserID
            self.total = votes.count
            self.leftCount = votes.filter { $0.winnerUserID == leftUserID }.count
            self.myWinnerUserID = votes.first { $0.voterID == voterID }?.winnerUserID
        }

        var hasVoted: Bool {
            myWinnerUserID != nil
        }

        func percent(for userID: String) -> Int? {
            guard total > 0 else { return nil }
            let leftPercent = Int((Double(leftCount) / Double(total) * 100).rounded())
            if userID == leftUserID {
                return leftPercent
            }
            if userID == rightUserID {
                return 100 - leftPercent
            }
            return nil
        }
    }

    @Published private(set) var votes: [Vote] = []

    init() {
        votes = Self.load()
    }

    func tally(week: Int, matchupID: Int, leftUserID: String, rightUserID: String) -> Tally {
        let leagueID = SleeperConfig.leagueID
        let matching = votes.filter {
            $0.leagueID == leagueID
                && $0.week == week
                && $0.matchupID == matchupID
        }
        return Tally(
            votes: matching,
            leftUserID: leftUserID,
            rightUserID: rightUserID,
            voterID: AppGroup.voterID
        )
    }

    @discardableResult
    func cast(week: Int, matchupID: Int, winnerUserID: String) -> Bool {
        let leagueID = SleeperConfig.leagueID
        let voterID = AppGroup.voterID
        guard matchupID != 0, !winnerUserID.isEmpty, !leagueID.isEmpty else {
            return false
        }
        if votes.contains(where: {
            $0.leagueID == leagueID
                && $0.week == week
                && $0.matchupID == matchupID
                && $0.voterID == voterID
        }) {
            return false
        }

        votes.append(
            Vote(
                leagueID: leagueID,
                week: week,
                matchupID: matchupID,
                voterID: voterID,
                winnerUserID: winnerUserID
            )
        )
        persist()
        return true
    }

    func adoptDeviceVotes(as userID: String) {
        let deviceID = AppGroup.deviceVoterID
        guard !userID.isEmpty, !deviceID.isEmpty, deviceID != userID else {
            return
        }

        var claimed: [Vote] = []
        var seen = Set<String>()
        var changed = false

        for vote in votes {
            var next = vote
            if next.voterID == deviceID {
                next.voterID = userID
                changed = true
            }
            if seen.insert(next.id).inserted {
                claimed.append(next)
            } else {
                changed = true
            }
        }

        guard changed else { return }
        votes = claimed
        persist()
    }

    private func persist() {
        guard let url = AppGroup.matchupVotesURL else { return }
        do {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(votes)
            try data.write(to: url, options: .atomic)
        } catch {
            print("Matchup ballot write failed: \(error.localizedDescription)")
        }
    }

    private static func load() -> [Vote] {
        guard let url = AppGroup.matchupVotesURL,
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([Vote].self, from: data) else {
            return []
        }
        return decoded
    }
}
