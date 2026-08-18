//
//  MatchupLiveActivity.swift
//  Draft
//
//  Created by John Chavez on 8/17/26.
//

#if os(iOS) && !targetEnvironment(macCatalyst) && canImport(ActivityKit)
import ActivityKit
import Foundation

enum MatchupLiveActivity {
    static func sync(_ snapshot: RankWidgetSnapshot) {
        guard #available(iOS 16.2, *) else { return }
        guard AppGroup.hasMyTeam,
              let me = snapshot.team(id: AppGroup.myUserID),
              let opponent = me.opponent(in: snapshot) else {
            endAll()
            return
        }

        let state = MatchupActivityAttributes.ContentState(
            myScore: me.weekPoints,
            opponentScore: opponent.weekPoints,
            myRecord: me.record,
            opponentRecord: opponent.record,
            myRank: me.rank,
            opponentRank: opponent.rank
        )

        let attributes = MatchupActivityAttributes(
            leagueName: snapshot.leagueName,
            week: snapshot.week,
            myTeam: me.teamName,
            opponentName: opponent.teamName,
            myUserID: me.userID
        )

        let existing = Activity<MatchupActivityAttributes>.activities

        if GameDay.isGameDay() {
            if let activity = existing.first {
                Task { await activity.update(.init(state: state, staleDate: nil)) }
            } else {
                do {
                    _ = try Activity.request(
                        attributes: attributes,
                        content: .init(state: state, staleDate: nil),
                        pushType: nil
                    )
                } catch {
                    print("Live Activity start failed: \(error.localizedDescription)")
                }
            }
        } else {
            endAll()
        }
    }

    static func endAll() {
        guard #available(iOS 16.2, *) else { return }
        for activity in Activity<MatchupActivityAttributes>.activities {
            Task { await activity.end(nil, dismissalPolicy: .after(.now + 60 * 30)) }
        }
    }
}
#endif
