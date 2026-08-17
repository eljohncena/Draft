//
//  TeamInfoView.swift
//  Draft
//
//  Created by John Chavez on 9/11/23.
//

import SwiftUI

struct TeamInfoView: View {

    @ObservedObject var manager: ContentViewController
    var userTeamInfo: UsersAndMatchups
    @AppStorage("sleeperMyUserID", store: AppGroup.defaults) private var myUserID = ""

    private var current: UsersAndMatchups {
        manager.usersAndRosters.first {
            $0.usersAndRosters.userGameWinLossTie.rosterID == userTeamInfo.usersAndRosters.userGameWinLossTie.rosterID
        } ?? userTeamInfo
    }

    private var players: [String: PlayersInfo] {
        manager.players
    }

    private var week: Int {
        manager.selectedWeek
    }

    private var roster: RostersInfo {
        current.usersAndRosters.userGameWinLossTie
    }

    private var starterIDs: [String] {
        roster.starters.filter { $0 != "0" && !$0.isEmpty }
    }

    private var benchIDs: [String] {
        let starting = Set(starterIDs)
        return roster.players.filter { $0 != "0" && !$0.isEmpty && !starting.contains($0) }
    }

    var body: some View {
        List {
            Section {
                header
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
            }

            if !starterIDs.isEmpty {
                Section("Starters") {
                    ForEach(starterIDs, id: \.self) { playerID in
                        NavigationLink(value: playerRoute(playerID)) {
                            playerRow(playerID)
                        }
                    }
                }
            }

            if !benchIDs.isEmpty {
                Section("Bench") {
                    ForEach(benchIDs, id: \.self) { playerID in
                        NavigationLink(value: playerRoute(playerID)) {
                            playerRow(playerID)
                        }
                    }
                }
            }

            if starterIDs.isEmpty && benchIDs.isEmpty {
                Section {
                    Text("No players rostered yet. This league has not drafted — switch leagues or wait until they do.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(current.usersAndRosters.user.metaData.teamName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: PlayerNewsRoute.self) { route in
            PlayerNewsView(
                playerID: route.playerID,
                player: players[route.playerID],
                weekPoints: route.weekPoints,
                week: week
            )
        }
        .task(id: starterIDs.joined(separator: ",") + "|" + benchIDs.joined(separator: ",")) {
            await manager.ensurePlayers(starterIDs + benchIDs)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if current.usersAndRosters.user.userID == myUserID {
                    Text("Your team")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("This is your team")
                } else {
                    Button("That’s me") {
                        SleeperConfig.rememberMe(
                            userID: current.usersAndRosters.user.userID,
                            displayName: current.usersAndRosters.user.metaData.teamName
                        )
                    }
                    .accessibilityHint("Use this team on widgets and Live Activities.")
                }
            }
        }
    }

    private func playerRoute(_ playerID: String) -> PlayerNewsRoute {
        PlayerNewsRoute(
            playerID: playerID,
            weekPoints: Double(current.matchups.playerPoints[playerID] ?? 0)
        )
    }

    private var header: some View {
        VStack(spacing: 16) {
            TeamAvatar(image: current.usersAndRosters.user.displayAvatar, size: 88)

            GlassEffectContainer(spacing: 12) {
                HStack(spacing: 12) {
                    GlassStatChip(
                        title: "Record",
                        value: DraftFormat.record(
                            wins: current.weekRecord.wins,
                            ties: current.weekRecord.ties,
                            losses: current.weekRecord.losses
                        )
                    )
                    GlassStatChip(title: "Season PF", value: DraftFormat.points(roster.settings.totalPoints))
                    GlassStatChip(title: "Week \(week)", value: DraftFormat.points(current.matchups.points))
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func playerRow(_ playerID: String) -> some View {
        let player = players[playerID]
        let points = current.matchups.playerPoints[playerID] ?? 0
        return HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(player?.displayName ?? playerID)
                    .font(.headline)
                if let detail = player?.positionTeam, !detail.isEmpty {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let injury = player?.injuryStatus, !injury.isEmpty {
                    Text(injury)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.orange)
                }
            }
            Spacer()
            Text(DraftFormat.points(points))
                .font(.body.weight(.semibold).monospacedDigit())
                .minimumScaleFactor(0.8)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(playerRowLabel(playerID, player: player, points: points))
    }

    private func playerRowLabel(_ playerID: String, player: PlayersInfo?, points: Float) -> String {
        var parts = [player?.displayName ?? playerID]
        if let detail = player?.positionTeam, !detail.isEmpty {
            parts.append(detail)
        }
        if let injury = player?.injuryStatus, !injury.isEmpty {
            parts.append(injury)
        }
        parts.append("\(DraftFormat.points(points)) points")
        return parts.joined(separator: ", ")
    }
}

struct PlayerNewsView: View {

    var playerID: String
    var player: PlayersInfo?
    var weekPoints: Double
    var week: Int

    @State private var playerNews: [NewsItem] = []
    @State private var teamNews: [NewsItem] = []
    @State private var isLoading = false

    private let controller = NewsController()

    private var resolved: PlayersInfo {
        player ?? PlayersInfo(playerID: playerID)
    }

    var body: some View {
        List {
            Section {
                header
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
            }

            Section("Player") {
                if playerNews.isEmpty && !isLoading {
                    Text("No recent notes for \(resolved.displayName).")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(playerNews) { item in
                        NewsRow(item: item)
                    }
                }
            }

            if !resolved.team.isEmpty {
                Section("\(resolved.team) news") {
                    if teamNews.isEmpty && !isLoading {
                        Text("No recent \(resolved.team) headlines.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(teamNews) { item in
                            NewsRow(item: item)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(resolved.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            if isLoading && playerNews.isEmpty && teamNews.isEmpty {
                ProgressView()
                    .controlSize(.large)
                    .padding(20)
                    .glassEffect(.regular.interactive(), in: Circle())
            }
        }
        .task(id: playerID) {
            await load()
        }
    }

    private var header: some View {
        VStack(spacing: 16) {
            Text(resolved.displayName)
                .font(.title2.weight(.semibold))
            if !resolved.positionTeam.isEmpty {
                Text(resolved.positionTeam)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            GlassEffectContainer(spacing: 12) {
                HStack(spacing: 12) {
                    if !resolved.injuryStatus.isEmpty {
                        GlassStatChip(title: "Status", value: resolved.injuryStatus)
                    }
                    GlassStatChip(title: "Week \(week)", value: DraftFormat.points(weekPoints))
                    if !resolved.team.isEmpty {
                        GlassStatChip(title: "NFL", value: resolved.team)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func load() async {
        isLoading = true
        async let sleeper = controller.fetchPlayerNews(playerID: playerID)
        async let espn = controller.fetchNFLNews()

        let sleeperItems = (try? await sleeper) ?? []
        let espnItems = (try? await espn) ?? []

        let nameMatched = espnItems.filter { $0.mentions(player: resolved) }
        var seen = Set<String>()
        playerNews = (sleeperItems + nameMatched)
            .sorted { ($0.published ?? .distantPast) > ($1.published ?? .distantPast) }
            .filter { seen.insert($0.id).inserted }

        teamNews = espnItems.filter { item in
            !nameMatched.contains(item) && item.mentions(team: resolved.team)
        }
        isLoading = false
    }
}

struct NewsRow: View {
    var item: NewsItem

    @Environment(\.openURL) private var openURL

    var body: some View {
        Button {
            if let url = item.url {
                openURL(url)
            }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                if let imageURL = item.imageURL {
                    AsyncImage(url: imageURL) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Color.primary.opacity(0.08)
                    }
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(item.title)
                        .font(.headline)
                        .foregroundStyle(Color.primary)
                        .multilineTextAlignment(.leading)
                    if !item.summary.isEmpty {
                        Text(item.summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                    }
                    HStack(spacing: 8) {
                        Text(item.source.replacingOccurrences(of: "_", with: " "))
                        if let published = item.published {
                            Text(published, style: .relative)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.title)
        .accessibilityValue([item.summary, item.source].filter { !$0.isEmpty }.joined(separator: ". "))
        .accessibilityHint(item.url == nil ? "" : "Opens article")
    }
}

struct TeamInfoView_Previews: PreviewProvider {
    static var previews: some View {
        let players = [
            "1373": PlayersInfo(playerID: "1373", firstName: "Geno", lastName: "Smith", fullName: "Geno Smith", position: "QB", team: "NYJ"),
            "9509": PlayersInfo(playerID: "9509", firstName: "Bijan", lastName: "Robinson", fullName: "Bijan Robinson", position: "RB", team: "ATL")
        ]
        let user = UsersAndMatchups(
            usersAndRosters: UsersWithInfo(
                user: UsersInfo(
                    userID: "98782",
                    displayName: "NotGreenBay",
                    avatarImage: UIImage(systemName: "questionmark"),
                    metaData: UsersInfo.MetaData(teamName: "NotGreenBay", avatarURL: "")
                ),
                userGameWinLossTie: RostersInfo(
                    settings: RostersInfo.Settings(wins: 1, ties: 0, losses: 0, totalPoints: 112.4),
                    rosterID: 1,
                    userID: "98782",
                    players: ["1373", "9509"],
                    starters: ["1373"]
                )
            ),
            matchups: MatchupsInfo(
                rosterID: 1,
                points: 27.08,
                matchupID: 1,
                playerPoints: ["1373": 18.70, "9509": 8.38]
            )
        )

        let manager = ContentViewController()
        manager.players = players

        return NavigationStack {
            TeamInfoView(manager: manager, userTeamInfo: user)
        }
    }
}
