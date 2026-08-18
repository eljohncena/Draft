//
//  ContentViewController.swift
//  test
//
//  Created by John Chavez on 9/9/23.
//

import Foundation
import SwiftUI

@MainActor
class ContentViewController: ObservableObject{
    let leagueController = LeagueController()
    var userController = UsersController()
    let rosterController = RostersController()
    let matchupController = MatchupsController()
    let playersController = PlayersController()
    
    @Published var name = ""
    @Published var totalRoster = 0
    @Published var season = ""
    @Published var users: [UsersInfo] = []
    @Published var rosters: [RostersInfo] = []
    @Published var week: Int = 0
    
    @Published var usersWithInfo:[UsersWithInfo] = []
    @Published var matchups: [MatchupsInfo] = []
    @Published var usersAndRosters: [UsersAndMatchups] = []
    @Published var players: [String: PlayersInfo] = [:]
    @Published var selectedWeek: Int = 1
    private var matchupsByWeek: [Int: [MatchupsInfo]] = [:]

    var latestSelectableWeek: Int {
        max(week, 1)
    }
    
    enum ViewControllerError: Error {
        case localizedError
        case fetchFailed
    }
    
    func startProcess() async {
        async let incomingPlayers = loadPlayersMap()
        let cached = LeagueStore.load()
        if let cached, !LeagueStore.shouldRefresh(cachedLeagueID: cached.leagueID) {
            apply(cached)
        } else {
            do {
                var snapshot = try await LeagueRefresher.fetch(includeAvatars: true)
                if snapshot.users.isEmpty, let cached, cached.leagueID == SleeperConfig.leagueID {
                    apply(cached)
                } else {
                    if !snapshot.users.isEmpty {
                        if let cached, cached.leagueID == snapshot.leagueID {
                            var weeks = cached.matchupsByWeek
                            for (weekNumber, weekMatchups) in snapshot.matchupsByWeek {
                                weeks[weekNumber] = weekMatchups
                            }
                            snapshot.matchupsByWeek = weeks
                        }
                        LeagueStore.save(snapshot)
                    }
                    apply(snapshot)
                    #if os(iOS)
                    Task { await LeagueAlerts.evaluate(previous: cached, current: snapshot) }
                    #endif
                }
            } catch {
                if let cached, cached.leagueID == SleeperConfig.leagueID {
                    print("Network refresh failed; using cache")
                    apply(cached)
                } else {
                    print("League info process failed: \(ViewControllerError.localizedError)")
                }
            }
        }

        players = await incomingPlayers
        await ensureMatchups(through: selectedWeek)
        applyMatchups(for: selectedWeek)
    }

    func selectLeague(_ leagueID: String) async {
        SleeperConfig.leagueID = leagueID
        name = ""
        usersAndRosters = []
        matchups = []
        matchupsByWeek = [:]
        selectedWeek = 1
        await startProcess()
    }

    private func loadPlayersMap() async -> [String: PlayersInfo] {
        do {
            let fetched = try await playersController.fetchPlayers()
            print("Players process and decode successful")
            return fetched
        } catch {
            print("Players info process failed \(ViewControllerError.localizedError)")
            return [:]
        }
    }

    func ensurePlayers(_ ids: [String]) async {
        let needed = ids.filter { $0 != "0" && !$0.isEmpty }
        guard needed.contains(where: { players[$0] == nil }) else { return }

        if players.isEmpty {
            let fetched = await loadPlayersMap()
            if !fetched.isEmpty {
                players = fetched
            }
        }

        let missing = needed.filter { players[$0] == nil }
        guard !missing.isEmpty else { return }

        var updates: [String: PlayersInfo] = [:]
        let controller = playersController
        await withTaskGroup(of: (String, PlayersInfo?).self) { group in
            for id in missing.prefix(40) {
                group.addTask {
                    (id, try? await controller.fetchPlayer(id: id))
                }
            }
            for await (id, player) in group {
                if let player {
                    updates[id] = player
                }
            }
        }

        if !updates.isEmpty {
            players.merge(updates) { _, new in new }
        }
    }

    private func apply(_ snapshot: LeagueSnapshot) {
        totalRoster = snapshot.totalRosters
        name = snapshot.name
        season = snapshot.season
        week = snapshot.week
        users = snapshot.users
        rosters = snapshot.rosters
        matchupsByWeek = snapshot.matchupsByWeek
        selectedWeek = max(snapshot.week, 1)
        usersWithInfo = combineUsersAndRosters()
        applyMatchups(for: selectedWeek)
        LeagueStore.publishWidget(from: snapshot)
        SavedLeagues.remember(
            LeagueSummary(
                leagueID: snapshot.leagueID,
                name: snapshot.name,
                season: snapshot.season,
                totalRosters: snapshot.totalRosters
            )
        )
    }

    func loadWeek(_ newWeek: Int) async {
        let clamped = min(max(newWeek, 1), latestSelectableWeek)
        selectedWeek = clamped
        await ensureMatchups(through: clamped)
        applyMatchups(for: clamped)
    }

    private func ensureMatchups(through week: Int) async {
        let missing = (1...max(week, 1)).filter { matchupsByWeek[$0] == nil }
        guard !missing.isEmpty else { return }

        let controller = matchupController
        await withTaskGroup(of: (Int, [MatchupsInfo]?).self) { group in
            for weekNumber in missing {
                group.addTask {
                    do {
                        return (weekNumber, try await controller.fetchMatchupsInfo(week: weekNumber))
                    } catch {
                        return (weekNumber, nil)
                    }
                }
            }

            for await (weekNumber, fetched) in group {
                if let fetched {
                    matchupsByWeek[weekNumber] = fetched
                }
            }
        }

        LeagueStore.save(currentSnapshot())
    }

    private func applyMatchups(for week: Int) {
        matchups = matchupsByWeek[week] ?? []
        usersAndRosters = combineUsersAndMatchups(usersAndRosters: usersWithInfo)
    }

    private func currentSnapshot() -> LeagueSnapshot {
        LeagueSnapshot(
            leagueID: SleeperConfig.leagueID,
            name: name,
            season: season,
            week: week,
            totalRosters: totalRoster,
            users: users,
            rosters: rosters,
            matchupsByWeek: matchupsByWeek
        )
    }

    
    func combineUsersAndRosters() -> [UsersWithInfo] {
        return self.users.map { user in
            guard let userStatistics = self.rosters.first(where: { $0.userID == user.userID }) else {
                let rosterInfoSettings = RostersInfo.Settings(wins: 0, ties: 0, losses: 0)
                let defaultRostersInfo = RostersInfo(settings: rosterInfoSettings ,rosterID: 0, userID: "")
                print("CombineUsersAndRoster func Failed")
                return UsersWithInfo(user: user, userGameWinLossTie: defaultRostersInfo)

            }
            print("CombineUsersAndRoster func success")
            return UsersWithInfo(user: user, userGameWinLossTie: userStatistics)
        }
    }

    func combineUsersAndMatchups(usersAndRosters: [UsersWithInfo]) -> [UsersAndMatchups] {
        return usersAndRosters.map { user in
            guard let userStatistics = self.matchups.first(where: { $0.rosterID == user.userGameWinLossTie.rosterID }) else {

                let defaultUsersWithInfo = UsersWithInfo(user: user.user, userGameWinLossTie: user.userGameWinLossTie)
                print("combineUsersAndMatchups func Failed")
                return UsersAndMatchups(
                    usersAndRosters: defaultUsersWithInfo,
                    matchups: MatchupsInfo(rosterID: user.userGameWinLossTie.rosterID, points: 0, matchupID: 0),
                    weekRecord: WeekRecord.through(
                        week: selectedWeek,
                        rosterID: user.userGameWinLossTie.rosterID,
                        matchupsByWeek: matchupsByWeek
                    )
                )

                    }
            print("combineUsersAndMatchups func success")
            return UsersAndMatchups(
                usersAndRosters: user,
                matchups: userStatistics,
                weekRecord: WeekRecord.through(
                    week: selectedWeek,
                    rosterID: user.userGameWinLossTie.rosterID,
                    matchupsByWeek: matchupsByWeek
                )
            )
                }
            }
}
