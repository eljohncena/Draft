//
//  MatchupLiveActivityWidget.swift
//  DraftWidget
//
//  Created by John Chavez on 8/17/26.
//

#if os(iOS) && !targetEnvironment(macCatalyst) && canImport(ActivityKit)
import ActivityKit
import SwiftUI
import WidgetKit

struct MatchupLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MatchupActivityAttributes.self) { context in
            lockScreen(context)
                .widgetURL(DraftRoute.matchup(userID: context.attributes.myUserID).url)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    scoreStack(
                        name: context.attributes.myTeam,
                        score: context.state.myScore,
                        record: context.state.myRecord
                    )
                }
                DynamicIslandExpandedRegion(.trailing) {
                    scoreStack(
                        name: context.attributes.opponentName,
                        score: context.state.opponentScore,
                        record: context.state.opponentRecord
                    )
                }
                DynamicIslandExpandedRegion(.center) {
                    Text("W\(context.attributes.week)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } compactLeading: {
                Text(shortScore(context.state.myScore))
                    .monospacedDigit()
            } compactTrailing: {
                Text(shortScore(context.state.opponentScore))
                    .monospacedDigit()
            } minimal: {
                Text(shortScore(context.state.myScore))
                    .monospacedDigit()
            }
            .widgetURL(DraftRoute.matchup(userID: context.attributes.myUserID).url)
        }
    }

    private func lockScreen(_ context: ActivityViewContext<MatchupActivityAttributes>) -> some View {
        HStack(alignment: .center, spacing: 12) {
            scoreStack(
                name: context.attributes.myTeam,
                score: context.state.myScore,
                record: context.state.myRecord
            )
            Text("VS")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            scoreStack(
                name: context.attributes.opponentName,
                score: context.state.opponentScore,
                record: context.state.opponentRecord
            )
        }
        .padding(16)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(context.attributes.myTeam) \(String(format: "%.2f", context.state.myScore)) versus \(context.attributes.opponentName) \(String(format: "%.2f", context.state.opponentScore)), week \(context.attributes.week)"
        )
    }

    private func scoreStack(name: String, score: Double, record: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(name)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
            Text(String(format: "%.2f", score))
                .font(.title2.weight(.semibold).monospacedDigit())
                .minimumScaleFactor(0.7)
            Text(record)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func shortScore(_ value: Double) -> String {
        String(format: "%.0f", value)
    }
}
#endif
