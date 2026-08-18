//
//  NFLScoreboard.swift
//  Draft
//
//  Created by John Chavez on 8/17/26.
//

import SwiftUI

struct NFLGame: Identifiable, Hashable {
    var id: String
    var awayAbbr: String
    var homeAbbr: String
    var awayScore: String
    var homeScore: String
    var awayWon: Bool
    var homeWon: Bool
    var state: String
    var statusText: String
    var start: Date?

    var isLive: Bool { state == "in" }
    var isFinal: Bool { state == "post" }
    var showsScore: Bool { isLive || isFinal }

    var chipStatus: String {
        if isLive { return "LIVE" }
        if isFinal { return "Final" }
        if let start {
            return Self.kickoffFormatter.string(from: start)
        }
        return statusText
    }

    var accessibilityLabel: String {
        var parts = ["\(awayAbbr) at \(homeAbbr)"]
        if showsScore {
            parts.append("\(awayScore) to \(homeScore)")
            if awayWon {
                parts.append("\(awayAbbr) won")
            } else if homeWon {
                parts.append("\(homeAbbr) won")
            }
        }
        parts.append(isLive ? "live" : chipStatus)
        return parts.joined(separator: ", ")
    }

    private static let kickoffFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "America/New_York")
        formatter.dateFormat = "E h:mma"
        return formatter
    }()
}

enum NFLScoreboard {
    private static var cache: (fetchedAt: Date, games: [NFLGame])?
    private static let liveCacheDuration: TimeInterval = 60
    private static let idleCacheDuration: TimeInterval = 5 * 60

    static func games(from data: Data) throws -> [NFLGame] {
        try sort(JSONDecoder().decode(ESPNScoreboard.self, from: data).games)
    }

    static func fetch(force: Bool = false) async -> [NFLGame] {
        if !force, let cache {
            let limit = cache.games.contains(where: \.isLive) ? liveCacheDuration : idleCacheDuration
            if Date().timeIntervalSince(cache.fetchedAt) < limit {
                return cache.games
            }
        }

        guard let games = await loadGames() else {
            return cache?.games ?? []
        }

        Self.cache = (Date(), games)
        return games
    }

    private static func loadGames() async -> [NFLGame]? {
        guard let board = await download() else { return nil }
        return sort(board.games)
    }

    private static func download() async -> ESPNScoreboard? {
        guard let url = URL(string: "https://site.api.espn.com/apis/site/v2/sports/football/nfl/scoreboard") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.setValue("okhttp/4.12.0", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            guard code == 200 else { return nil }
            return try JSONDecoder().decode(ESPNScoreboard.self, from: data)
        } catch {
            print("NFL scoreboard failed: \(error.localizedDescription)")
            return nil
        }
    }

    private static func sort(_ games: [NFLGame]) -> [NFLGame] {
        games.sorted { lhs, rhs in
            let left = rank(lhs.state)
            let right = rank(rhs.state)
            if left != right { return left < right }
            return (lhs.start ?? .distantPast) < (rhs.start ?? .distantPast)
        }
    }

    private static func rank(_ state: String) -> Int {
        switch state {
        case "in": return 0
        case "pre": return 1
        default: return 2
        }
    }
}

struct NFLScoreBanner: View {
    var games: [NFLGame]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(games) { game in
                    NFLScoreChip(game: game)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 2)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("NFL scores")
    }
}

private struct NFLScoreChip: View {
    var game: NFLGame

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            teamRow(abbr: game.awayAbbr, score: game.awayScore, won: game.awayWon)
            teamRow(abbr: game.homeAbbr, score: game.homeScore, won: game.homeWon)
            Text(game.chipStatus)
                .font(.caption2.weight(game.isLive ? .semibold : .regular))
                .foregroundStyle(game.isLive ? Color.red : Color.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .font(.caption2)
        .frame(width: 88, alignment: .leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .draftGlass(in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(game.accessibilityLabel)
    }

    private func teamRow(abbr: String, score: String, won: Bool) -> some View {
        HStack(spacing: 6) {
            Text(abbr)
                .fontWeight(won ? .semibold : .regular)
                .foregroundStyle(won || !game.showsScore ? Color.primary : Color.secondary)
                .lineLimit(1)
            Spacer(minLength: 2)
            if game.showsScore {
                Text(score)
                    .font(.caption2.monospacedDigit().weight(won ? .semibold : .regular))
                    .foregroundStyle(won ? Color.primary : Color.secondary)
            }
        }
    }
}

private struct ESPNScoreboard: Decodable {
    var events: [ESPNEvent] = []

    var games: [NFLGame] {
        events.compactMap(\.game)
    }
}

private struct ESPNEvent: Decodable {
    var id: ESPNFlexibleString?
    var date: String?
    var shortName: String?
    var status: ESPNStatus?
    var competitions: [ESPNCompetition]?

    var game: NFLGame? {
        let competition = competitions?.first
        let competitors = competition?.competitors ?? []
        guard
            let away = competitors.first(where: { $0.homeAway == "away" }),
            let home = competitors.first(where: { $0.homeAway == "home" })
        else { return nil }

        let state = status?.type?.state ?? "pre"
        return NFLGame(
            id: id?.value ?? shortName ?? UUID().uuidString,
            awayAbbr: away.team?.abbreviation ?? "AWY",
            homeAbbr: home.team?.abbreviation ?? "HME",
            awayScore: away.score?.value ?? "0",
            homeScore: home.score?.value ?? "0",
            awayWon: away.winner ?? false,
            homeWon: home.winner ?? false,
            state: state,
            statusText: status?.type?.shortDetail ?? status?.type?.description ?? "",
            start: Self.parseDate(date)
        )
    }

    private static let dateParser: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static func parseDate(_ raw: String?) -> Date? {
        guard let raw else { return nil }
        if let date = dateParser.date(from: raw) { return date }
        let fallback = ISO8601DateFormatter()
        fallback.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fallback.date(from: raw)
    }
}

private struct ESPNStatus: Decodable {
    var type: ESPNStatusType?
}

private struct ESPNStatusType: Decodable {
    var state: String?
    var shortDetail: String?
    var description: String?
}

private struct ESPNCompetition: Decodable {
    var competitors: [ESPNCompetitor]?
}

private struct ESPNCompetitor: Decodable {
    var homeAway: String?
    var score: ESPNFlexibleString?
    var winner: Bool?
    var team: ESPNTeam?
}

private struct ESPNTeam: Decodable {
    var abbreviation: String?
}

private struct ESPNFlexibleString: Decodable {
    var value: String

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = String(int)
        } else if let double = try? container.decode(Double.self) {
            value = String(Int(double))
        } else {
            value = ""
        }
    }
}
