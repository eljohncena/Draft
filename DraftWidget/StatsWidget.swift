//
//  StatsWidget.swift
//  DraftWidget
//
//  Created by John Chavez on 8/17/26.
//

import SwiftUI
import WidgetKit

struct StatsWidgetEntryView: View {
    var entry: RankEntry

    var body: some View {
        Group {
            if let snapshot = entry.snapshot, let team = entry.team {
                StatsLargeView(snapshot: snapshot, team: team)
            } else {
                RankWidgetEmptyView(title: "Team Stats", message: "Open Draft to load team stats.")
            }
        }
        .widgetURL(widgetURL)
    }

    private var widgetURL: URL {
        if let team = entry.team {
            return DraftRoute.team(userID: team.userID).url
        }
        return DraftRoute.standings.url
    }
}

struct StatsLargeView: View {
    var snapshot: RankWidgetSnapshot
    var team: RankWidgetSnapshot.Team

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            WidgetHeader(snapshot: snapshot)
            Text(team.teamName)
                .font(.title2.weight(.semibold))
                .lineLimit(2)

            HStack(spacing: 12) {
                stat("Rank", "\(team.rank) of \(snapshot.teams.count)")
                stat("Record", team.record)
            }
            HStack(spacing: 12) {
                stat("Season PF", String(format: "%.2f", team.pointsFor))
                stat("Week \(snapshot.week)", String(format: "%.2f", team.weekPoints))
            }

            if let opponent = team.opponent(in: snapshot) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Opponent")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(opponent.teamName)  \(String(format: "%.2f", opponent.weekPoints))")
                        .font(.headline)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) {
            WidgetChrome.background()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(team.teamName), rank \(team.rank), record \(team.record), season points \(String(format: "%.2f", team.pointsFor)), week \(snapshot.week) \(String(format: "%.2f", team.weekPoints))"
        )
    }

    private func stat(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline.monospacedDigit())
                .minimumScaleFactor(0.8)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct StatsWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: RankWidgetCache.statsKind,
            intent: RankWidgetIntent.self,
            provider: RankProvider()
        ) { entry in
            StatsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Team Stats")
        .description("Rank, record, points for, and this week’s score.")
        .supportedFamilies([.systemLarge])
    }
}

struct StandingsWidgetEntryView: View {
    var entry: RankEntry

    var body: some View {
        Group {
            if let snapshot = entry.snapshot, !snapshot.teams.isEmpty {
                StandingsExtraLargeView(snapshot: snapshot, selectedID: entry.teamID)
            } else {
                RankWidgetEmptyView(title: "Standings", message: "Open Draft to load standings.")
            }
        }
        .widgetURL(DraftRoute.standings.url)
    }
}

struct StandingsExtraLargeView: View {
    var snapshot: RankWidgetSnapshot
    var selectedID: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            WidgetHeader(snapshot: snapshot)
            ForEach(snapshot.teams.prefix(14)) { team in
                HStack(spacing: 8) {
                    Text("\(team.rank)")
                        .font(.caption.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 18, alignment: .trailing)
                    Text(team.teamName)
                        .font(.subheadline.weight(team.userID == selectedID ? .semibold : .regular))
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Text(team.record)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.1f", team.weekPoints))
                        .font(.caption.monospacedDigit())
                        .frame(width: 44, alignment: .trailing)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(team.rank). \(team.teamName), \(team.record)")
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) {
            WidgetChrome.background()
        }
    }
}

struct StandingsWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: RankWidgetCache.standingsKind,
            intent: RankWidgetIntent.self,
            provider: RankProvider()
        ) { entry in
            StandingsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Standings")
        .description("League rank, record, and this week’s points.")
        .supportedFamilies([.systemExtraLarge])
    }
}

#Preview(as: .systemLarge) {
    StatsWidget()
} timeline: {
    RankEntry(date: .now, snapshot: .placeholder, teamID: "1")
}
