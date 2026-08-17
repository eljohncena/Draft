//
//  MatchupWidget.swift
//  DraftWidget
//
//  Created by John Chavez on 8/17/26.
//

import SwiftUI
import WidgetKit

struct MatchupWidgetEntryView: View {
    var entry: RankEntry

    var body: some View {
        Group {
            if let snapshot = entry.snapshot, let team = entry.team {
                MatchupMediumView(snapshot: snapshot, team: team)
            } else {
                RankWidgetEmptyView(title: "Matchup", message: "Open Draft to load this week’s matchup.")
            }
        }
        .widgetURL(widgetURL)
    }

    private var widgetURL: URL {
        if let team = entry.team {
            return DraftRoute.matchup(userID: team.userID).url
        }
        return DraftRoute.standings.url
    }
}

struct MatchupMediumView: View {
    var snapshot: RankWidgetSnapshot
    var team: RankWidgetSnapshot.Team

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            WidgetHeader(snapshot: snapshot)
            HStack(alignment: .center, spacing: 8) {
                teamColumn(team)
                Text("VS")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                if let opponent = team.opponent(in: snapshot) {
                    teamColumn(opponent)
                } else {
                    VStack(spacing: 4) {
                        Text("Bye")
                            .font(.subheadline.weight(.semibold))
                        Text("No matchup")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) {
            WidgetChrome.background()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
    }

    private func teamColumn(_ team: RankWidgetSnapshot.Team) -> some View {
        VStack(spacing: 4) {
            Text(team.teamName)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)
            Text(String(format: "%.2f", team.weekPoints))
                .font(.title2.weight(.semibold).monospacedDigit())
                .minimumScaleFactor(0.7)
            Text(team.record)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
            Text("#\(team.rank)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var label: String {
        if let opponent = team.opponent(in: snapshot) {
            return "\(team.teamName) versus \(opponent.teamName), \(String(format: "%.2f", team.weekPoints)) to \(String(format: "%.2f", opponent.weekPoints)), week \(snapshot.week)"
        }
        return "\(team.teamName) has no matchup in week \(snapshot.week)"
    }
}

struct MatchupWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: RankWidgetCache.matchupKind,
            intent: RankWidgetIntent.self,
            provider: RankProvider()
        ) { entry in
            MatchupWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("This Week’s Matchup")
        .description("Your team against this week’s opponent.")
        .supportedFamilies([.systemMedium])
    }
}

#Preview(as: .systemMedium) {
    MatchupWidget()
} timeline: {
    RankEntry(date: .now, snapshot: .placeholder, teamID: "1")
}
