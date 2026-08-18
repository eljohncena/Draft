//
//  LeagueAlerts.swift
//  Draft
//
//  Created by John Chavez on 8/17/26.
//

#if os(iOS)
import Foundation
import UserNotifications

enum LeagueAlerts {
    static func requestAccess() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            let allowed = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            AppGroup.alertsEnabled = allowed
            return allowed
        } catch {
            AppGroup.alertsEnabled = false
            return false
        }
    }

    static func evaluate(previous: LeagueSnapshot?, current: LeagueSnapshot) async {
        guard AppGroup.alertsEnabled, AppGroup.hasMyTeam else { return }
        await notifyRecordChange(previous: previous, current: current)
        await notifyInjuries(in: current)
    }

    private static func notifyRecordChange(previous: LeagueSnapshot?, current: LeagueSnapshot) async {
        guard let mine = current.rosters.first(where: { $0.userID == AppGroup.myUserID }) else {
            return
        }
        let key = "\(current.leagueID)|\(mine.rosterID)"
        let fingerprint = "\(mine.settings.wins)-\(mine.settings.ties)-\(mine.settings.losses)"
        let previousKey = AppGroup.lastRecordFingerprint
        AppGroup.lastRecordFingerprint = "\(key)|\(fingerprint)"

        guard let previous,
              let old = previous.rosters.first(where: { $0.userID == AppGroup.myUserID }),
              previous.leagueID == current.leagueID else {
            return
        }
        guard previousKey.hasPrefix(key) else { return }

        let team = current.users.first { $0.userID == mine.userID }?.metaData.teamName
            ?? AppGroup.myDisplayName
        if mine.settings.wins > old.settings.wins {
            await post(
                id: "win-\(current.week)-\(mine.settings.wins)",
                title: "\(team) won",
                body: "You're now \(DraftFormat.record(wins: mine.settings.wins, ties: mine.settings.ties, losses: mine.settings.losses))."
            )
        } else if mine.settings.losses > old.settings.losses {
            await post(
                id: "loss-\(current.week)-\(mine.settings.losses)",
                title: "\(team) lost",
                body: "Record is \(DraftFormat.record(wins: mine.settings.wins, ties: mine.settings.ties, losses: mine.settings.losses))."
            )
        }
    }

    private static func notifyInjuries(in snapshot: LeagueSnapshot) async {
        guard let mine = snapshot.rosters.first(where: { $0.userID == AppGroup.myUserID }) else {
            return
        }
        let ids = mine.players.filter { $0 != "0" && !$0.isEmpty }
        let previous = AppGroup.injuryStatuses
        var next: [String: String] = [:]
        var fresh: [(String, String)] = []
        let controller = PlayersController()

        await withTaskGroup(of: (String, PlayersInfo?).self) { group in
            for id in ids.prefix(16) {
                group.addTask {
                    (id, try? await controller.fetchPlayer(id: id))
                }
            }
            for await (id, player) in group {
                let status = player?.injuryStatus ?? ""
                next[id] = status
                let old = previous[id] ?? ""
                if !previous.isEmpty, !status.isEmpty, status != old {
                    let name = player?.displayName ?? id
                    fresh.append((name, status))
                }
            }
        }

        AppGroup.injuryStatuses = next
        for event in fresh.prefix(3) {
            await post(
                id: "injury-\(event.0)-\(event.1)",
                title: "\(event.0) is \(event.1)",
                body: "Update on your \(snapshot.name.isEmpty ? "league" : snapshot.name) roster."
            )
        }
    }

    private static func post(id: String, title: String, body: String) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        try? await UNUserNotificationCenter.current().add(request)
    }
}

final class LeagueAlertCenter: NSObject, UNUserNotificationCenterDelegate {
    static let shared = LeagueAlertCenter()

    func activate() {
        UNUserNotificationCenter.current().delegate = self
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
#endif
