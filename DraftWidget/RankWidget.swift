//
//  RankWidget.swift
//  DraftWidget
//
//  Created by John Chavez on 8/17/26.
//

import SwiftUI
import WidgetKit

struct RankWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: RankEntry

    var body: some View {
        Group {
            if let snapshot = entry.snapshot, let team = entry.team {
                switch family {
                case .accessoryCircular:
                    RankCircularView(team: team)
                case .accessoryRectangular:
                    RankRectangularView(snapshot: snapshot, team: team)
                case .accessoryInline:
                    Text("\(team.rank) \(team.record)")
                        .privacySensitive(false)
                #if os(watchOS)
                case .accessoryCorner:
                    Text("\(team.rank)")
                        .font(.title.weight(.bold))
                        .widgetLabel {
                            Text(team.record)
                        }
                        .containerBackground(for: .widget) {
                            AccessoryWidgetBackground()
                        }
                        .accessibilityLabel("Rank \(team.rank), \(team.record)")
                #endif
                default:
                    RankSmallView(snapshot: snapshot, team: team)
                }
            } else {
                RankWidgetEmptyView(title: "Rank", message: "Open Draft to load league rank and record.")
            }
        }
        #if !os(watchOS)
        .widgetURL(rankWidgetURL)
        #endif
    }

    #if !os(watchOS)
    private var rankWidgetURL: URL {
        if let team = entry.team {
            return DraftRoute.team(userID: team.userID).url
        }
        return DraftRoute.standings.url
    }
    #endif
}

struct RankSmallView: View {
    var snapshot: RankWidgetSnapshot
    var team: RankWidgetSnapshot.Team

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            WidgetHeader(snapshot: snapshot)
            Spacer(minLength: 4)
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(team.rank)")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text("of \(snapshot.teams.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(team.teamName)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
            Text(team.record)
                .font(.headline.monospacedDigit())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) {
            WidgetChrome.background()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(team.teamName), rank \(team.rank) of \(snapshot.teams.count), record \(team.record), week \(snapshot.week)")
    }
}

struct RankCircularView: View {
    var team: RankWidgetSnapshot.Team

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Text("\(team.rank)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                Text(team.record)
                    .font(.caption2.monospacedDigit())
                    .minimumScaleFactor(0.6)
            }
        }
        .containerBackground(for: .widget) {
            AccessoryWidgetBackground()
        }
        .accessibilityLabel("Rank \(team.rank), \(team.record)")
    }
}

struct RankRectangularView: View {
    var snapshot: RankWidgetSnapshot
    var team: RankWidgetSnapshot.Team

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(team.teamName)
                .font(.headline)
                .lineLimit(1)
            Text("\(team.rank) of \(snapshot.teams.count)  \(team.record)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .containerBackground(for: .widget) {
            AccessoryWidgetBackground()
        }
        .accessibilityLabel("\(team.teamName), rank \(team.rank), \(team.record)")
    }
}

struct RankWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: RankWidgetCache.kind,
            intent: RankWidgetIntent.self,
            provider: RankProvider()
        ) { entry in
            RankWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("League Rank")
        .description("Season rank and win–tie–loss record.")
        .supportedFamilies(Self.families)
    }

    private static var families: [WidgetFamily] {
        #if os(watchOS)
        [.accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner]
        #else
        [.systemSmall, .accessoryCircular, .accessoryRectangular, .accessoryInline]
        #endif
    }
}

#if !os(watchOS)
#Preview(as: .systemSmall) {
    RankWidget()
} timeline: {
    RankEntry(date: .now, snapshot: .placeholder, teamID: "1")
    RankEntry(date: .now, snapshot: nil, teamID: nil)
}
#endif
