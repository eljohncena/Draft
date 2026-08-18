//
//  LeagueStore.swift
//  Draft
//
//  Created by John Chavez on 8/17/26.
//

import CoreData
import SwiftUI

enum LeagueStore {
    private static var context: NSManagedObjectContext {
        PersistenceController.shared.viewContext
    }

    /// NFL scoring days in Eastern Time, matching the README game-day list.
    static func isGameDay(_ date: Date = Date()) -> Bool {
        GameDay.isGameDay(date)
    }

    static func shouldRefresh(cachedLeagueID: String) -> Bool {
        cachedLeagueID != SleeperConfig.leagueID || isGameDay()
    }

    static func load() -> LeagueSnapshot? {
        let context = context
        let leagueRequest = LeagueCache.fetchRequest()
        leagueRequest.fetchLimit = 1

        guard let league = try? context.fetch(leagueRequest).first,
              let leagueID = league.leagueID,
              leagueID == SleeperConfig.leagueID else {
            return nil
        }

        let userRequest = UserEntity.fetchRequest()
        userRequest.sortDescriptors = [NSSortDescriptor(key: "rosterID", ascending: true)]
        guard let userEntities = try? context.fetch(userRequest), !userEntities.isEmpty else {
            return nil
        }

        let week = Int(league.week)
        var users: [UsersInfo] = []
        var rosters: [RostersInfo] = []
        var matchupsByWeek: [Int: [MatchupsInfo]] = [:]

        for entity in userEntities {
            let userID = entity.userID ?? ""
            let displayName = entity.displayName ?? ""
            let teamName = entity.teamName ?? displayName
            let avatarURL = entity.avatarURL ?? ""
            let avatarImage = entity.avatarData.flatMap(UIImage.init(data:))
            users.append(
                UsersInfo(
                    userID: userID,
                    displayName: displayName,
                    avatarImage: avatarImage,
                    metaData: UsersInfo.MetaData(teamName: teamName, avatarURL: avatarURL)
                )
            )

            let totals = entity.totalSummary
            rosters.append(
                RostersInfo(
                    settings: RostersInfo.Settings(
                        wins: Int(totals?.totalWins ?? 0),
                        ties: Int(totals?.totalTies ?? 0),
                        losses: Int(totals?.totalLosses ?? 0),
                        totalPoints: totals?.totalPoints ?? 0
                    ),
                    rosterID: Int(entity.rosterID),
                    userID: userID,
                    players: Self.splitIDs(entity.playerIDs),
                    starters: Self.splitIDs(entity.starterIDs)
                )
            )

            if let weeklies = entity.weeklySummaries as? Set<WeeklySummary> {
                for weekly in weeklies {
                    let weekNumber = Int(weekly.weekNumber)
                    matchupsByWeek[weekNumber, default: []].append(
                        MatchupsInfo(
                            rosterID: Int(weekly.rosterID),
                            points: Float(weekly.weeklyPoints),
                            matchupID: Int(weekly.matchupID),
                            playerPoints: Self.decodePlayerPoints(weekly.playerPointsJSON)
                        )
                    )
                }
            }
        }

        return LeagueSnapshot(
            leagueID: leagueID,
            name: league.name ?? "",
            season: league.season ?? "",
            week: week,
            totalRosters: Int(league.totalRosters),
            users: users,
            rosters: rosters,
            matchupsByWeek: matchupsByWeek
        )
    }

    static func save(_ snapshot: LeagueSnapshot) {
        let context = context

        let leagueRequest = LeagueCache.fetchRequest()
        let leagues = (try? context.fetch(leagueRequest)) ?? []
        let league = leagues.first ?? LeagueCache(context: context)
        for extra in leagues.dropFirst() {
            context.delete(extra)
        }
        league.leagueID = snapshot.leagueID
        league.name = snapshot.name
        league.season = snapshot.season
        league.week = Int16(snapshot.week)
        league.totalRosters = Int16(snapshot.totalRosters)
        league.lastRefreshed = Date()

        let keepIDs = Set(snapshot.users.map(\.userID))
        let userRequest = UserEntity.fetchRequest()
        for entity in (try? context.fetch(userRequest)) ?? [] {
            if !keepIDs.contains(entity.userID ?? "") {
                context.delete(entity)
            }
        }

        for user in snapshot.users {
            let roster = snapshot.rosters.first { $0.userID == user.userID }
            upsert(
                user: user,
                roster: roster,
                matchupsByWeek: snapshot.matchupsByWeek,
                in: context
            )
        }

        do {
            if context.hasChanges {
                try context.save()
            }
            print("League cache save successful")
        } catch {
            print("League cache save failed: \(error.localizedDescription)")
            context.rollback()
        }

        publishWidget(from: snapshot)
    }

    static func publishWidget(from snapshot: LeagueSnapshot) {
        guard !snapshot.users.isEmpty else { return }
        let payload = RankWidgetSnapshot.make(from: snapshot)
        RankWidgetCache.write(payload)
        WatchBridge.shared.push(payload)
        #if os(iOS) && !targetEnvironment(macCatalyst) && canImport(ActivityKit)
        MatchupLiveActivity.sync(payload)
        #endif
    }

    private static func upsert(
        user: UsersInfo,
        roster: RostersInfo?,
        matchupsByWeek: [Int: [MatchupsInfo]],
        in context: NSManagedObjectContext
    ) {
        let request = UserEntity.fetchRequest()
        request.predicate = NSPredicate(format: "userID == %@", user.userID)
        request.fetchLimit = 1
        let entity = (try? context.fetch(request))?.first ?? UserEntity(context: context)

        entity.userID = user.userID
        entity.displayName = user.displayName
        entity.teamName = user.metaData.teamName
        entity.avatarURL = user.metaData.avatarURL
        entity.rosterID = Int32(roster?.rosterID ?? 0)
        entity.playerIDs = Self.joinIDs(roster?.players ?? [])
        entity.starterIDs = Self.joinIDs(roster?.starters ?? [])
        if let pngData = user.avatarImage?.pngData() {
            entity.avatarData = pngData
        }

        let totals = entity.totalSummary ?? TotalSummary(context: context)
        totals.totalWins = Int16(roster?.settings.wins ?? 0)
        totals.totalTies = Int16(roster?.settings.ties ?? 0)
        totals.totalLosses = Int16(roster?.settings.losses ?? 0)
        totals.totalPoints = roster?.settings.totalPoints ?? 0
        totals.user = entity
        entity.totalSummary = totals

        guard let roster else { return }

        for (week, matchups) in matchupsByWeek {
            let matchup = matchups.first { $0.rosterID == roster.rosterID }
            let existing = (entity.weeklySummaries as? Set<WeeklySummary>)?
                .first { Int($0.weekNumber) == week }
            let weekly = existing ?? WeeklySummary(context: context)
            weekly.weekNumber = Int16(week)
            weekly.rosterID = Int32(roster.rosterID)
            weekly.weeklyPoints = Double(matchup?.points ?? 0)
            weekly.matchupID = Int32(matchup?.matchupID ?? 0)
            weekly.playerPointsJSON = Self.encodePlayerPoints(matchup?.playerPoints ?? [:])
            weekly.user = entity
        }
    }

    private static func joinIDs(_ ids: [String]) -> String {
        ids.joined(separator: ",")
    }

    private static func splitIDs(_ raw: String?) -> [String] {
        (raw ?? "")
            .split(separator: ",")
            .map(String.init)
            .filter { !$0.isEmpty }
    }

    private static func encodePlayerPoints(_ points: [String: Float]) -> String {
        guard let data = try? JSONEncoder().encode(points),
              let json = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return json
    }

    private static func decodePlayerPoints(_ json: String?) -> [String: Float] {
        guard let json, let data = json.data(using: .utf8) else {
            return [:]
        }
        return (try? JSONDecoder().decode([String: Float].self, from: data)) ?? [:]
    }
}
