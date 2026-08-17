//
//  DraftRoute.swift
//  Draft
//
//  Created by John Chavez on 8/17/26.
//

import Foundation

enum DraftRoute: Equatable {
    case standings
    case matchup(userID: String)
    case team(userID: String)

    static let scheme = "draft"

    var url: URL {
        switch self {
        case .standings:
            return URL(string: "\(Self.scheme)://standings")!
        case .matchup(let userID):
            return URL(string: "\(Self.scheme)://matchup/\(userID)")!
        case .team(let userID):
            return URL(string: "\(Self.scheme)://team/\(userID)")!
        }
    }

    static func parse(_ url: URL) -> DraftRoute? {
        guard url.scheme == scheme else { return nil }
        let host = url.host ?? ""
        let identifier = url.path.split(separator: "/").map(String.init).first ?? ""
        switch host {
        case "matchup":
            return .matchup(userID: identifier)
        case "team":
            return .team(userID: identifier)
        default:
            return .standings
        }
    }
}
