//
//  GameDay.swift
//  Draft
//
//  Created by John Chavez on 8/17/26.
//

import Foundation

enum GameDay {
    /// NFL scoring days in Eastern Time: Sunday, Monday, Thursday.
    static func isGameDay(_ date: Date = Date()) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York") ?? .current
        switch calendar.component(.weekday, from: date) {
        case 1, 2, 5:
            return true
        default:
            return false
        }
    }

    /// Past weeks stay locked. The current week locks at Thursday 8:15 PM ET
    /// (first NFL kickoff in a typical week) or as soon as any roster has scored.
    static func canChangeMatchupVote(
        selectedWeek: Int,
        currentWeek: Int,
        scoringHasStarted: Bool,
        now: Date = Date()
    ) -> Bool {
        if currentWeek < 1 {
            return true
        }
        if selectedWeek < currentWeek {
            return false
        }
        if scoringHasStarted {
            return false
        }
        if selectedWeek > currentWeek {
            return true
        }
        return now < firstKickoff(ofNFLWeekContaining: now)
    }

    /// NFL week runs Tuesday–Monday Eastern. Typical first kickoff is Thursday 8:15 PM ET.
    private static func firstKickoff(ofNFLWeekContaining date: Date) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York") ?? .current
        let weekday = calendar.component(.weekday, from: date)
        let daysFromThursday: Int
        switch weekday {
        case 1: daysFromThursday = -3
        case 2: daysFromThursday = -4
        case 3: daysFromThursday = 2
        case 4: daysFromThursday = 1
        case 5: daysFromThursday = 0
        case 6: daysFromThursday = -1
        default: daysFromThursday = -2
        }
        let start = calendar.startOfDay(for: date)
        let thursday = calendar.date(byAdding: .day, value: daysFromThursday, to: start) ?? start
        return calendar.date(bySettingHour: 20, minute: 15, second: 0, of: thursday) ?? thursday
    }
}

enum NewsSeason {
    static let nflHeadlineLimit = 20

    static func isActive(season: String, now: Date = Date()) -> Bool {
        interval(for: season)?.contains(now) == true
    }

    static func contains(published: Date?, season: String, now: Date = Date()) -> Bool {
        guard isActive(season: season, now: now) else { return false }
        guard let published else { return true }
        return interval(for: season)?.contains(published) == true
    }

    /// Regular season through Super Bowl: September 1 → February 16 Eastern.
    static func interval(for season: String) -> DateInterval? {
        guard let year = Int(season.filter(\.isNumber).prefix(4)), year > 2000 else {
            return nil
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York") ?? .current
        guard let start = calendar.date(from: DateComponents(year: year, month: 9, day: 1)),
              let end = calendar.date(from: DateComponents(year: year + 1, month: 2, day: 16)) else {
            return nil
        }
        return DateInterval(start: start, end: end)
    }
}
