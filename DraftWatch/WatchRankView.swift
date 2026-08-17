//
//  WatchRankView.swift
//  DraftWatch
//
//  Created by John Chavez on 8/17/26.
//

import SwiftUI

struct WatchRankView: View {
    @State private var snapshot = RankWidgetCache.read()
    @State private var selectedID: String? = AppGroup.myUserID.isEmpty ? nil : AppGroup.myUserID
    @State private var isLoading = false

    private var team: RankWidgetSnapshot.Team? {
        snapshot?.team(id: selectedID)
    }

    var body: some View {
        Group {
            if let snapshot, let team {
                VStack(alignment: .leading, spacing: 6) {
                    Text(snapshot.leagueName.isEmpty ? "Draft" : snapshot.leagueName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(team.rank)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text(team.teamName)
                        .font(.headline)
                        .lineLimit(2)
                    Text(team.record)
                        .font(.title3.monospacedDigit())
                    Text("W\(snapshot.week)  \(String(format: "%.1f", team.weekPoints))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(team.teamName), rank \(team.rank), \(team.record)")
            } else if isLoading {
                ProgressView("Loading league")
            } else {
                ContentUnavailableView(
                    "No league yet",
                    systemImage: "sportscourt",
                    description: Text("Open Draft on iPhone, or pull to refresh to load Wizards from Sleeper.")
                )
            }
        }
        .padding(.horizontal, 4)
        .navigationTitle("Rank")
        .task {
            WatchBridge.shared.activate()
            snapshot = RankWidgetCache.read()
            await refreshIfNeeded()
        }
        .refreshable {
            await fetchRemote()
        }
        .onReceive(NotificationCenter.default.publisher(for: .rankSnapshotDidChange)) { _ in
            snapshot = RankWidgetCache.read()
        }
    }

    private func refreshIfNeeded() async {
        snapshot = RankWidgetCache.read()
        if let snapshot {
            if !snapshot.leagueID.isEmpty {
                SleeperConfig.leagueID = snapshot.leagueID
            }
            if GameDay.isGameDay(), snapshot.updatedAt.timeIntervalSinceNow < -30 * 60 {
                await fetchRemote()
            }
        } else {
            await fetchRemote()
        }
    }

    private func fetchRemote() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let fetched = try await LeagueRefresher.fetch(includeAvatars: false)
            let ranked = RankWidgetSnapshot.make(from: fetched)
            RankWidgetCache.write(ranked)
            snapshot = ranked
        } catch {
            print("Watch league fetch failed: \(error.localizedDescription)")
        }
    }
}
