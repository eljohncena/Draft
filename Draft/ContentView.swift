//
//  ContentView.swift
//  test
//
//  Created by John Chavez on 9/9/23.
//

import SwiftUI

struct ContentView: View {

    enum AppTab: Hashable {
        case feed, standings, matchups, news, settings
    }

    @StateObject var manager = ContentViewController()
    @State private var tab: AppTab = .feed
    @State private var standingsPath = NavigationPath()
    @State private var pendingRoute: DraftRoute?

    var body: some View {
        TabView(selection: $tab) {
            NavigationStack {
                LeagueFeedView(
                    users: manager.usersAndRosters,
                    week: manager.selectedWeek,
                    players: manager.players,
                    leagueName: manager.name
                )
                .toolbar { weekToolbar }
            }
            .tabItem { Label("Feed", systemImage: "dot.radiowaves.up.forward") }
            .tag(AppTab.feed)

            NavigationStack(path: $standingsPath) {
                WeeklyStandingsView(users: manager.usersAndRosters, week: manager.selectedWeek)
                    .navigationTitle("Standings")
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar { weekToolbar }
                    .navigationDestination(for: UsersAndMatchups.self) { selected in
                        let current = manager.usersAndRosters.first {
                            $0.usersAndRosters.userGameWinLossTie.rosterID == selected.usersAndRosters.userGameWinLossTie.rosterID
                        } ?? selected
                        TeamInfoView(manager: manager, userTeamInfo: current)
                    }
            }
            .tabItem { Label("Standings", systemImage: "list.number") }
            .tag(AppTab.standings)

            NavigationStack {
                MatchupsView(
                    users: manager.usersAndRosters,
                    week: manager.selectedWeek,
                    currentWeek: manager.week
                )
                    .toolbar { weekToolbar }
            }
            .tabItem { Label("Matchups", systemImage: "arrow.left.arrow.right") }
            .tag(AppTab.matchups)

            NavigationStack {
                NewsView(
                    users: manager.usersAndRosters,
                    players: manager.players,
                    season: manager.season
                )
            }
            .tabItem { Label("News", systemImage: "newspaper") }
            .tag(AppTab.news)

            NavigationStack {
                SettingsView(manager: manager)
            }
            .tabItem { Label("Settings", systemImage: "gearshape") }
            .tag(AppTab.settings)
        }
        .modifier(TabBarMinimizeModifier())
        .task {
            await manager.startProcess()
            if let pendingRoute {
                open(pendingRoute)
            }
        }
        .onOpenURL { url in
            guard let route = DraftRoute.parse(url) else { return }
            open(route)
        }
        .onChange(of: manager.usersAndRosters.map(\.id).joined(separator: ",")) { _, _ in
            if let pendingRoute {
                open(pendingRoute)
            }
        }
    }

    private func open(_ route: DraftRoute) {
        switch route {
        case .standings:
            tab = .standings
            standingsPath = NavigationPath()
            pendingRoute = nil
        case .matchup:
            tab = .matchups
            pendingRoute = nil
        case .team(let userID):
            tab = .standings
            if let user = manager.usersAndRosters.first(where: { $0.usersAndRosters.user.userID == userID }) {
                standingsPath = NavigationPath()
                standingsPath.append(user)
                pendingRoute = nil
            } else {
                pendingRoute = route
            }
        }
    }

    @ToolbarContentBuilder
    private var weekToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                Task { await manager.loadWeek(manager.selectedWeek - 1) }
            } label: {
                Image(systemName: "chevron.left")
            }
            .disabled(manager.selectedWeek <= 1)
            .accessibilityLabel("Previous week")
        }
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                ForEach(1...manager.latestSelectableWeek, id: \.self) { week in
                    Button("Week \(week)") {
                        Task { await manager.loadWeek(week) }
                    }
                }
            } label: {
                Text("Week \(manager.selectedWeek)")
            }
            .accessibilityLabel("Select week")
            .accessibilityValue("Week \(manager.selectedWeek)")
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                Task { await manager.loadWeek(manager.selectedWeek + 1) }
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(manager.selectedWeek >= manager.latestSelectableWeek)
            .accessibilityLabel("Next week")
        }
    }
}

private struct TabBarMinimizeModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.tabBarMinimizeBehavior(.onScrollDown)
        } else {
            content
        }
    }
}

struct LeaguesView: View {

    @ObservedObject var manager: ContentViewController
    @AppStorage("sleeperMyUserID", store: AppGroup.defaults) private var myUserID = ""
    @AppStorage("sleeperMyDisplayName", store: AppGroup.defaults) private var myDisplayName = ""
    @State private var query = ""
    @State private var saved: [LeagueSummary] = SavedLeagues.all()
    @State private var isSearching = false
    @State private var message = ""
    @State private var foundUser: SleeperUser?

    private let controller = LeaguesController()

    var body: some View {
        List {
            Section("Playing") {
                currentLeague
                if !myUserID.isEmpty {
                    Text(myDisplayName.isEmpty ? "Your team is set for widgets." : "Your team: \(myDisplayName)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel(myDisplayName.isEmpty ? "Your team is set" : "Your team, \(myDisplayName)")
                }
            }

            if let foundUser, foundUser.userID != myUserID {
                Section("Sleeper account") {
                    Button {
                        SleeperConfig.remember(foundUser)
                        self.foundUser = nil
                        message = "Widgets will default to \(foundUser.displayName.isEmpty ? foundUser.username : foundUser.displayName)."
                    } label: {
                        Label(
                            "That’s me — \(foundUser.displayName.isEmpty ? foundUser.username : foundUser.displayName)",
                            systemImage: "person.crop.circle.badge.checkmark"
                        )
                    }
                    .accessibilityHint("Saves this Sleeper account as your team for widgets and Live Activities.")
                }
            }

            if !saved.isEmpty {
                Section("Saved") {
                    ForEach(saved) { league in
                        Button {
                            Task { await select(league) }
                        } label: {
                            leagueRow(league)
                        }
                    }
                    .onDelete(perform: deleteSaved)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Leagues")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, prompt: "Username or league ID")
        .onSubmit(of: .search) {
            Task { await search() }
        }
        .onAppear {
            saved = SavedLeagues.all()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Search") {
                    Task { await search() }
                }
                .draftProminentButton()
                .disabled(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSearching)
            }
        }
        .overlay {
            if isSearching {
                ProgressView()
                    .controlSize(.large)
                    .padding(20)
                    .draftGlass(in: Circle(), interactive: true)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !message.isEmpty {
                Text(message)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .draftGlass(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }
        }
    }

    private var currentLeague: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(manager.name.isEmpty ? "Loading…" : manager.name)
                .font(.headline)
            if !manager.season.isEmpty {
                Text("\(manager.season) · \(manager.totalRoster) teams")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Text(SleeperConfig.leagueID)
                .font(.caption.monospaced())
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(manager.name.isEmpty ? "Loading league" : manager.name), \(manager.season.isEmpty ? "" : "\(manager.season), ")\(manager.totalRoster) teams"
        )
        .accessibilityAddTraits(.isHeader)
    }

    private func leagueRow(_ league: LeagueSummary) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(league.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("\(league.season) · \(league.statusLabel) · \(league.totalRosters) teams")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if league.leagueID == SleeperConfig.leagueID {
                Image(systemName: "checkmark")
                    .foregroundStyle(.tint)
                    .accessibilityLabel("Selected")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(league.name), \(league.season), \(league.statusLabel), \(league.totalRosters) teams")
    }

    private func search() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSearching = true
        message = ""
        foundUser = nil
        do {
            if !trimmed.allSatisfy(\.isNumber), let user = try? await controller.fetchUser(trimmed), !user.userID.isEmpty {
                foundUser = user
            }
            let found = try await controller.searchLeagues(query: trimmed)
            if found.isEmpty {
                message = "No leagues found. Sleeper cannot search by league name — use a username or paste a league ID."
            } else {
                SavedLeagues.remember(found)
                saved = SavedLeagues.all()
                message = found.count == 1
                    ? "Saved \(found[0].name)."
                    : "Saved \(found.count) leagues. Tap one to switch."
            }
        } catch {
            message = "Search failed."
        }
        isSearching = false
    }

    private func select(_ league: LeagueSummary) async {
        SavedLeagues.remember(league)
        saved = SavedLeagues.all()
        await manager.selectLeague(league.leagueID)
        saved = SavedLeagues.all()
        message = "Loaded \(league.name)."
    }

    private func deleteSaved(at offsets: IndexSet) {
        for index in offsets {
            SavedLeagues.remove(saved[index].leagueID)
        }
        saved = SavedLeagues.all()
    }
}

struct NewsView: View {

    var users: [UsersAndMatchups]
    var players: [String: PlayersInfo]
    var season: String

    @AppStorage("sleeperMyUserID", store: AppGroup.defaults) private var myUserID = ""
    @State private var scope: Scope = .league
    @State private var query = ""
    @State private var nflNews: [NewsItem] = []
    @State private var sleeperNews: [NewsItem] = []
    @State private var isLoading = false
    @State private var message = ""

    private let controller = NewsController()

    private enum Scope: String, CaseIterable, Identifiable {
        case league = "League"
        case mine = "My team"
        case nfl = "NFL"

        var id: String { rawValue }
    }

    private var visibleScopes: [Scope] {
        myUserID.isEmpty ? [.league, .nfl] : Scope.allCases
    }

    private var myRoster: RostersInfo? {
        users.first { $0.usersAndRosters.user.userID == myUserID }?.usersAndRosters.userGameWinLossTie
    }

    private var myPlayerIDs: Set<String> {
        Set((myRoster?.players ?? []).filter { $0 != "0" && !$0.isEmpty })
    }

    private var rosteredPlayers: [PlayersInfo] {
        var seen = Set<String>()
        var result: [PlayersInfo] = []
        for user in users {
            for playerID in user.usersAndRosters.userGameWinLossTie.players where playerID != "0" && !playerID.isEmpty {
                guard seen.insert(playerID).inserted else { continue }
                result.append(players[playerID] ?? PlayersInfo(playerID: playerID))
            }
        }
        return result
    }

    private var isSeason: Bool {
        NewsSeason.isActive(season: season.isEmpty ? "2026" : season)
    }

    private var inSeasonNFL: [NewsItem] {
        seasonFiltered(nflNews)
    }

    private var inSeasonSleeper: [NewsItem] {
        seasonFiltered(sleeperNews)
    }

    private var nflHeadlines: [NewsItem] {
        let items = searched(inSeasonNFL)
        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return Array(items.prefix(NewsSeason.nflHeadlineLimit))
        }
        return items
    }

    private var rosteredTeams: [String] {
        Array(Set(rosteredPlayers.map(\.team).filter { !$0.isEmpty })).sorted()
    }

    private var playerStories: [NewsItem] {
        searched(stories(for: rosteredPlayers, includingSleeper: true))
    }

    private var teamStories: [NewsItem] {
        let playerIDs = Set(playerStories.map(\.id))
        return searched(inSeasonNFL.filter { article in
            !playerIDs.contains(article.id)
                && rosteredTeams.contains { article.mentions(team: $0) }
        })
    }

    private var myPlayers: [PlayersInfo] {
        rosteredPlayers.filter { myPlayerIDs.contains($0.playerID) }
    }

    private var myPlayerStories: [NewsItem] {
        searched(stories(for: myPlayers, includingSleeper: true))
    }

    private var myTeamStories: [NewsItem] {
        let myTeams = Array(Set(myPlayers.map(\.team).filter { !$0.isEmpty }))
        let playerIDs = Set(myPlayerStories.map(\.id))
        return searched(inSeasonNFL.filter { article in
            !playerIDs.contains(article.id)
                && myTeams.contains { article.mentions(team: $0) }
        })
    }

    private func stories(for watched: [PlayersInfo], includingSleeper: Bool) -> [NewsItem] {
        let fromESPN = inSeasonNFL.filter { article in
            watched.contains { article.mentions(player: $0) }
        }
        let sleeper = includingSleeper
            ? inSeasonSleeper.filter { item in
                watched.contains { item.mentions(player: $0) }
            }
            : []
        return deduped(sleeper + fromESPN)
    }

    private func seasonFiltered(_ items: [NewsItem]) -> [NewsItem] {
        let year = season.isEmpty ? "2026" : season
        return items
            .filter { NewsSeason.contains(published: $0.published, season: year) }
            .sorted { ($0.published ?? .distantPast) > ($1.published ?? .distantPast) }
    }

    private func searched(_ items: [NewsItem]) -> [NewsItem] {
        items.filter { $0.matches(query) }
    }

    var body: some View {
        List {
            Picker("News", selection: $scope) {
                ForEach(visibleScopes) { value in
                    Text(value.rawValue).tag(value)
                }
            }
            .pickerStyle(.segmented)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .onChange(of: myUserID) { _, id in
                if id.isEmpty, scope == .mine {
                    scope = .league
                }
            }

            if !isSeason {
                Section {
                    Text("Headlines show during the NFL season, September through the Super Bowl. Search still works once games start.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                switch scope {
                case .league:
                    if rosteredPlayers.isEmpty {
                        Section {
                            Text("No rostered players yet. NFL headlines are on the NFL tab. After the draft, this tab follows players and their NFL teams.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        newsSection("Players", items: playerStories, empty: emptyCopy(for: "players"))
                        newsSection("NFL teams", items: teamStories, empty: emptyCopy(for: "teams"))
                    }
                case .mine:
                    if myPlayers.isEmpty {
                        Section {
                            Text("Mark That’s me on your team to follow only your roster here.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        newsSection("Your players", items: myPlayerStories, empty: emptyCopy(for: "your roster"))
                        newsSection("Their NFL teams", items: myTeamStories, empty: emptyCopy(for: "your players’ clubs"))
                    }
                case .nfl:
                    newsSection("NFL", items: nflHeadlines, empty: emptyCopy(for: "the NFL"))
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("News")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $query, prompt: "Players, teams, headlines")
        .overlay {
            if isLoading && nflNews.isEmpty && sleeperNews.isEmpty {
                ProgressView()
                    .controlSize(.large)
                    .padding(20)
                    .draftGlass(in: Circle(), interactive: true)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !message.isEmpty {
                Text(message)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .draftGlass(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }
        }
        .refreshable {
            await load(forceSleeper: true)
        }
        .task(id: rosterSignature) {
            await load()
        }
    }

    private func emptyCopy(for topic: String) -> String {
        if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "No headlines match that search."
        }
        return "No recent news for \(topic)."
    }

    private var rosterSignature: String {
        rosteredPlayers.map(\.playerID).sorted().joined(separator: ",")
    }

    @ViewBuilder
    private func newsSection(_ title: String, items: [NewsItem], empty: String) -> some View {
        Section(title) {
            if items.isEmpty {
                Text(empty)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(items) { item in
                    NewsRow(item: item)
                }
            }
        }
    }

    private func load(forceSleeper: Bool = false) async {
        isLoading = true
        message = ""
        do {
            nflNews = try await controller.fetchNFLNews()
        } catch {
            if nflNews.isEmpty {
                message = "Could not load NFL news."
            }
        }

        let targets = sleeperTargets
        if forceSleeper || sleeperNews.isEmpty {
            sleeperNews = await controller.fetchNews(forPlayerIDs: targets)
        }
        isLoading = false
    }

    private var sleeperTargets: [String] {
        var ordered: [String] = []
        var seen = Set<String>()
        func append(_ ids: [String]) {
            for id in ids where id != "0" && !id.isEmpty && seen.insert(id).inserted {
                ordered.append(id)
            }
        }
        append(rosteredPlayers.filter { !$0.injuryStatus.isEmpty }.map(\.playerID))
        if let mine = myRoster {
            append(mine.starters)
            append(mine.players)
        }
        append(rosteredPlayers.map(\.playerID))
        return Array(ordered.prefix(12))
    }

    private func deduped(_ items: [NewsItem]) -> [NewsItem] {
        var seen = Set<String>()
        return items
            .sorted { ($0.published ?? .distantPast) > ($1.published ?? .distantPast) }
            .filter { seen.insert($0.id).inserted }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
