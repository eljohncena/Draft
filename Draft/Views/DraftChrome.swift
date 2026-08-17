//
//  DraftChrome.swift
//  Draft
//
//  Created by John Chavez on 8/17/26.
//

import SwiftUI

enum DraftFormat {
    static func points(_ value: Double) -> String {
        String(format: "%.2f", value)
    }

    static func points(_ value: Float) -> String {
        String(format: "%.2f", value)
    }

    static func record(wins: Int, ties: Int, losses: Int) -> String {
        "\(wins)–\(ties)–\(losses)"
    }
}

struct TeamAvatar: View {
    let image: UIImage
    var size: CGFloat = 48

    @ScaledMetric(relativeTo: .body) private var scale: CGFloat = 1

    var body: some View {
        let side = size * scale
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: side, height: side)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .strokeBorder(Color.primary.opacity(0.18), lineWidth: 1)
            }
            .accessibilityHidden(true)
    }
}

struct GlassStatChip: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline.monospacedDigit())
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title) \(value)")
    }
}

struct TeamStandingsRow: View {
    let user: UsersAndMatchups
    var rank: Int
    var week: Int
    var isMine: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 22, alignment: .center)
                .accessibilityHidden(true)

            TeamAvatar(image: user.usersAndRosters.user.displayAvatar)

            VStack(alignment: .leading, spacing: 2) {
                Text(user.usersAndRosters.user.metaData.teamName)
                    .font(.headline)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    Text(DraftFormat.record(wins: user.weekRecord.wins, ties: user.weekRecord.ties, losses: user.weekRecord.losses))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if isMine {
                        Text("You")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.tint)
                    }
                }
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                Text(DraftFormat.points(user.matchups.points))
                    .font(.title3.weight(.semibold).monospacedDigit())
                Text("PF \(DraftFormat.points(user.weekRecord.pointsFor))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(rank). \(user.usersAndRosters.user.metaData.teamName)\(isMine ? ", your team" : ""), record \(DraftFormat.record(wins: user.weekRecord.wins, ties: user.weekRecord.ties, losses: user.weekRecord.losses)), week \(week) \(DraftFormat.points(user.matchups.points)) points, season \(DraftFormat.points(user.weekRecord.pointsFor)) points for"
        )
    }
}
