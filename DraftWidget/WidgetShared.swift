//
//  WidgetShared.swift
//  DraftWidget
//
//  Created by John Chavez on 8/17/26.
//

import AppIntents
import SwiftUI
import WidgetKit

struct RankTeamEntity: AppEntity, Identifiable {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Team"
    static var defaultQuery = RankTeamQuery()

    var id: String
    var name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct RankTeamQuery: EntityQuery {
    func entities(for identifiers: [RankTeamEntity.ID]) async throws -> [RankTeamEntity] {
        teams().filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [RankTeamEntity] {
        teams()
    }

    func defaultResult() async -> RankTeamEntity? {
        let all = teams()
        let mine = AppGroup.myUserID
        if !mine.isEmpty, let match = all.first(where: { $0.id == mine }) {
            return match
        }
        return all.first
    }

    private func teams() -> [RankTeamEntity] {
        (RankWidgetCache.read()?.teams ?? []).map {
            RankTeamEntity(id: $0.userID, name: $0.teamName)
        }
    }
}

struct RankWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Team"
    static var description = IntentDescription("Choose a team in the current Sleeper league.")

    @Parameter(title: "Team")
    var team: RankTeamEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Show \(\.$team)")
    }
}

struct RankEntry: TimelineEntry {
    let date: Date
    let snapshot: RankWidgetSnapshot?
    let teamID: String?

    var team: RankWidgetSnapshot.Team? {
        snapshot?.team(id: teamID)
    }
}

struct RankProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> RankEntry {
        RankEntry(date: .now, snapshot: .placeholder, teamID: RankWidgetSnapshot.placeholder.teams.first?.userID)
    }

    func snapshot(for configuration: RankWidgetIntent, in context: Context) async -> RankEntry {
        entry(for: configuration)
    }

    func timeline(for configuration: RankWidgetIntent, in context: Context) async -> Timeline<RankEntry> {
        Timeline(entries: [entry(for: configuration)], policy: .after(Self.nextReloadDate()))
    }

    func recommendations() -> [AppIntentRecommendation<RankWidgetIntent>] {
        (RankWidgetCache.read()?.teams ?? []).prefix(5).map { team in
            let intent = RankWidgetIntent()
            intent.team = RankTeamEntity(id: team.userID, name: team.teamName)
            return AppIntentRecommendation(intent: intent, description: LocalizedStringResource(stringLiteral: team.teamName))
        }
    }

    private func entry(for configuration: RankWidgetIntent) -> RankEntry {
        RankEntry(date: .now, snapshot: RankWidgetCache.read(), teamID: configuration.team?.id)
    }

    static func nextReloadDate(now: Date = Date()) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York") ?? .current
        switch calendar.component(.weekday, from: now) {
        case 1, 2, 5:
            return now.addingTimeInterval(60 * 60)
        default:
            return now.addingTimeInterval(6 * 60 * 60)
        }
    }
}

struct WidgetChrome {
    @ViewBuilder
    static func background() -> some View {
        #if os(watchOS)
        AccessoryWidgetBackground()
        #else
        Color(.systemBackground)
        #endif
    }
}

struct RankWidgetEmptyView: View {
    var title: String
    var message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) {
            WidgetChrome.background()
        }
        .accessibilityLabel(message)
        #if !os(watchOS)
        .widgetURL(DraftRoute.standings.url)
        #endif
    }
}

struct WidgetHeader: View {
    var snapshot: RankWidgetSnapshot

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(snapshot.leagueName.isEmpty ? "Draft" : snapshot.leagueName)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Spacer(minLength: 6)
            Text("W\(snapshot.week)")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }
}

extension RankWidgetSnapshot {
    static let placeholder = RankWidgetSnapshot(
        leagueID: "preview",
        leagueName: "Wizards",
        season: "2026",
        week: 1,
        teams: [
            Team(userID: "1", rosterID: 1, teamName: "MoneyTeamFC", displayName: "Money", rank: 1, wins: 3, ties: 0, losses: 0, pointsFor: 412.4, weekPoints: 118.2, matchupID: 1, opponentUserID: "2"),
            Team(userID: "2", rosterID: 2, teamName: "ta1ktomEnice", displayName: "Talk", rank: 4, wins: 2, ties: 0, losses: 1, pointsFor: 356.1, weekPoints: 101.4, matchupID: 1, opponentUserID: "1"),
            Team(userID: "3", rosterID: 3, teamName: "NotGreenBay", displayName: "GB", rank: 2, wins: 2, ties: 1, losses: 0, pointsFor: 388.0, weekPoints: 96.2, matchupID: 2, opponentUserID: "4"),
            Team(userID: "4", rosterID: 4, teamName: "Waffle House", displayName: "Waffle", rank: 3, wins: 2, ties: 0, losses: 1, pointsFor: 371.8, weekPoints: 88.0, matchupID: 2, opponentUserID: "3")
        ],
        updatedAt: Date()
    )
}
