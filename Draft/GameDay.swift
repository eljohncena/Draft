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
}
