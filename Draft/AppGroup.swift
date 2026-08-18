//
//  AppGroup.swift
//  Draft
//
//  Created by John Chavez on 8/17/26.
//

import Foundation

enum AppGroup {
    static let identifier = "group.com.example.DraftFantasy"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }

    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }

    static var snapshotURL: URL? {
        supportDirectory?.appendingPathComponent("rank-widget.json", isDirectory: false)
    }

    static var matchupVotesURL: URL? {
        supportDirectory?.appendingPathComponent("matchup-votes.json", isDirectory: false)
    }

    private static var supportDirectory: URL? {
        containerURL?
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)
    }

    static var myUserID: String {
        get { defaults.string(forKey: "sleeperMyUserID") ?? "" }
        set { defaults.set(newValue, forKey: "sleeperMyUserID") }
    }

    static var myUsername: String {
        get { defaults.string(forKey: "sleeperMyUsername") ?? "" }
        set { defaults.set(newValue, forKey: "sleeperMyUsername") }
    }

    static var myDisplayName: String {
        get { defaults.string(forKey: "sleeperMyDisplayName") ?? "" }
        set { defaults.set(newValue, forKey: "sleeperMyDisplayName") }
    }

    static var hasMyTeam: Bool {
        !myUserID.isEmpty
    }

    /// Sleeper user when “That’s me” is set; otherwise a stable per-device voter.
    static var voterID: String {
        if !myUserID.isEmpty {
            return myUserID
        }
        if let existing = defaults.string(forKey: "sleeperVoterID"), !existing.isEmpty {
            return existing
        }
        let generated = "device-" + UUID().uuidString
        defaults.set(generated, forKey: "sleeperVoterID")
        return generated
    }

    static var deviceVoterID: String {
        defaults.string(forKey: "sleeperVoterID") ?? ""
    }

    static var didOnboard: Bool {
        get { defaults.bool(forKey: "sleeperDidOnboard") }
        set { defaults.set(newValue, forKey: "sleeperDidOnboard") }
    }

    static var alertsEnabled: Bool {
        get { defaults.bool(forKey: "sleeperAlertsEnabled") }
        set { defaults.set(newValue, forKey: "sleeperAlertsEnabled") }
    }

    static var lastRecordFingerprint: String {
        get { defaults.string(forKey: "sleeperLastRecord") ?? "" }
        set { defaults.set(newValue, forKey: "sleeperLastRecord") }
    }

    static var injuryStatuses: [String: String] {
        get {
            guard let data = defaults.data(forKey: "sleeperInjuryStatuses"),
                  let map = try? JSONDecoder().decode([String: String].self, from: data) else {
                return [:]
            }
            return map
        }
        set {
            defaults.set((try? JSONEncoder().encode(newValue)) ?? Data(), forKey: "sleeperInjuryStatuses")
        }
    }
}
