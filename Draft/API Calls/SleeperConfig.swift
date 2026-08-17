//
//  SleeperConfig.swift
//  Draft
//
//  Created by John Chavez on 8/17/26.
//

import Foundation

enum SleeperConfig {
    /// THE WIZARDS FANTASY FOOTBALL LEAGUE, 2026.
    /// Streets @ South ’23 (989252508654567424) has no live continuation.
    static let defaultLeagueID = "1312062559569862656"
    private static let storageKey = "sleeperLeagueID"

    static var leagueID: String {
        get {
            let grouped = AppGroup.defaults.string(forKey: storageKey) ?? ""
            if !grouped.isEmpty {
                return grouped
            }
            let legacy = UserDefaults.standard.string(forKey: storageKey) ?? ""
            if !legacy.isEmpty {
                AppGroup.defaults.set(legacy, forKey: storageKey)
                return legacy
            }
            return defaultLeagueID
        }
        set {
            AppGroup.defaults.set(newValue, forKey: storageKey)
            UserDefaults.standard.set(newValue, forKey: storageKey)
        }
    }

    static func remember(_ user: SleeperUser) {
        rememberMe(
            userID: user.userID,
            displayName: user.displayName.isEmpty ? user.username : user.displayName,
            username: user.username
        )
    }

    static func rememberMe(userID: String, displayName: String, username: String = "") {
        guard !userID.isEmpty else { return }
        AppGroup.myUserID = userID
        if !displayName.isEmpty {
            AppGroup.myDisplayName = displayName
        }
        if !username.isEmpty {
            AppGroup.myUsername = username
        }
        RankWidgetCache.reload()
        if let snapshot = RankWidgetCache.read() {
            WatchBridge.shared.push(snapshot)
            #if os(iOS) && canImport(ActivityKit)
            MatchupLiveActivity.sync(snapshot)
            #endif
        }
    }
}
