//
//  RankWidgetSnapshot.swift
//  Draft
//
//  Created by John Chavez on 8/17/26.
//

import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

struct RankWidgetSnapshot: Codable, Hashable {
    var leagueID: String
    var leagueName: String
    var season: String
    var week: Int
    var teams: [Team]
    var updatedAt: Date

    struct Team: Codable, Hashable, Identifiable {
        var userID: String
        var rosterID: Int
        var teamName: String
        var displayName: String
        var rank: Int
        var wins: Int
        var ties: Int
        var losses: Int
        var pointsFor: Double
        var weekPoints: Double
        var matchupID: Int
        var opponentUserID: String?

        var id: String { userID }

        var record: String {
            "\(wins)–\(ties)–\(losses)"
        }

        func opponent(in snapshot: RankWidgetSnapshot) -> Team? {
            guard let opponentUserID else { return nil }
            return snapshot.teams.first { $0.userID == opponentUserID }
        }
    }

    func team(id: String?) -> Team? {
        if let id, !id.isEmpty, let match = teams.first(where: { $0.userID == id }) {
            return match
        }
        let mine = AppGroup.myUserID
        if !mine.isEmpty, let match = teams.first(where: { $0.userID == mine }) {
            return match
        }
        return teams.first
    }
}

enum RankWidgetCache {
    static let kind = "DraftRankWidget"
    static let matchupKind = "DraftMatchupWidget"
    static let statsKind = "DraftStatsWidget"
    static let standingsKind = "DraftStandingsWidget"

    static func write(_ snapshot: RankWidgetSnapshot) {
        guard let url = AppGroup.snapshotURL else {
            print("Rank widget snapshot skipped: App Group container missing")
            return
        }

        do {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            try encoder.encode(snapshot).write(to: url, options: .atomic)
            NotificationCenter.default.post(name: .rankSnapshotDidChange, object: nil)
            reload()
        } catch {
            print("Rank widget snapshot write failed: \(error.localizedDescription)")
        }
    }

    static func read() -> RankWidgetSnapshot? {
        guard let url = AppGroup.snapshotURL,
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(RankWidgetSnapshot.self, from: data)
    }

    static func reload() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}

extension Notification.Name {
    static let rankSnapshotDidChange = Notification.Name("RankWidgetSnapshotDidChange")
}
