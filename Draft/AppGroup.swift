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
        containerURL?
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent("rank-widget.json", isDirectory: false)
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
}
