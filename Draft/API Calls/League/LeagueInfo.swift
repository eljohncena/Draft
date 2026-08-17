//
//  leagueInfo.swift
//  test
//
//  Created by John Chavez on 9/9/23.
//


import Foundation
import UIKit


struct LeagueInfo: Decodable {
    
    var totalRosters: Int = 0
    var name: String = ""
    var season: String = ""
    
    var settings: Settings
    struct Settings {
        var leg: Int
    }
    
    enum CodingKeys: String, CodingKey {
        case totalRosters = "total_rosters"
        case name
        case season
        case settings
        
        enum SettingsCodingKeys: String, CodingKey {
            case leg
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.totalRosters = try container.decode(Int.self, forKey: .totalRosters)
        self.name = try container.decode(String.self, forKey: .name)
        self.season = try container.decode(String.self, forKey: .season)
        
        do {
            
            let settingsContainer = try container.nestedContainer(keyedBy: CodingKeys.SettingsCodingKeys.self, forKey: .settings)
            let leg = try settingsContainer.decode(Int.self, forKey: .leg )
            settings = Settings(leg: leg)
        } catch DecodingError.keyNotFound {
            print("Error Decoding LeagueInfo leg")
            settings = Settings(leg: 0)
        }

    }
    
}

struct LeagueSummary: Codable, Identifiable, Hashable {
    var leagueID: String = ""
    var name: String = ""
    var season: String = ""
    var status: String = ""
    var totalRosters: Int = 0

    var id: String { leagueID }

    var statusLabel: String {
        status.replacingOccurrences(of: "_", with: " ")
    }

    enum CodingKeys: String, CodingKey {
        case leagueID = "league_id"
        case name
        case season
        case status
        case totalRosters = "total_rosters"
    }

    init(leagueID: String, name: String, season: String, status: String = "", totalRosters: Int = 0) {
        self.leagueID = leagueID
        self.name = name
        self.season = season
        self.status = status
        self.totalRosters = totalRosters
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        leagueID = try container.decodeIfPresent(String.self, forKey: .leagueID) ?? ""
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        season = try container.decodeIfPresent(String.self, forKey: .season) ?? ""
        status = try container.decodeIfPresent(String.self, forKey: .status) ?? ""
        totalRosters = try container.decodeIfPresent(Int.self, forKey: .totalRosters) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(leagueID, forKey: .leagueID)
        try container.encode(name, forKey: .name)
        try container.encode(season, forKey: .season)
        try container.encode(status, forKey: .status)
        try container.encode(totalRosters, forKey: .totalRosters)
    }
}

enum SavedLeagues {
    private static let key = "sleeperSavedLeagues"
    private static let maxCount = 20

    static func all() -> [LeagueSummary] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let leagues = try? JSONDecoder().decode([LeagueSummary].self, from: data) else {
            return []
        }
        return leagues
    }

    static func remember(_ league: LeagueSummary) {
        remember([league])
    }

    static func remember(_ incoming: [LeagueSummary]) {
        var leagues = all()
        for league in incoming.reversed() {
            upsert(&leagues, league)
        }
        save(leagues)
    }

    static func remove(_ leagueID: String) {
        var leagues = all()
        leagues.removeAll { $0.leagueID == leagueID }
        save(leagues)
    }

    private static func upsert(_ leagues: inout [LeagueSummary], _ league: LeagueSummary) {
        guard !league.leagueID.isEmpty else { return }
        if let index = leagues.firstIndex(where: { $0.leagueID == league.leagueID }) {
            var merged = league
            if merged.name.isEmpty { merged.name = leagues[index].name }
            if merged.status.isEmpty { merged.status = leagues[index].status }
            if merged.season.isEmpty { merged.season = leagues[index].season }
            if merged.totalRosters == 0 { merged.totalRosters = leagues[index].totalRosters }
            leagues.remove(at: index)
            leagues.insert(merged, at: 0)
        } else {
            leagues.insert(league, at: 0)
        }
        if leagues.count > maxCount {
            leagues = Array(leagues.prefix(maxCount))
        }
    }

    private static func save(_ leagues: [LeagueSummary]) {
        if let data = try? JSONEncoder().encode(leagues) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

struct SleeperUser: Decodable {
    var userID: String = ""
    var username: String = ""
    var displayName: String = ""

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case username
        case displayName = "display_name"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userID = try container.decodeIfPresent(String.self, forKey: .userID) ?? ""
        username = try container.decodeIfPresent(String.self, forKey: .username) ?? ""
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName) ?? ""
    }
}
