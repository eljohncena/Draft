//
//  PlayersController.swift
//  Draft
//
//  Created by John Chavez on 8/17/26.
//

import Foundation

class PlayersController {

    enum PlayersControllerError: Error, LocalizedError {
        case itemNotFound
        case decodingFailed
    }

    private struct PlayersCacheFile: Codable {
        var savedAt: Date
        var players: [String: PlayersInfo]
    }

    func fetchPlayers() async throws -> [String: PlayersInfo] {
        if let cached = loadCache(), !isStale(cached.savedAt) {
            print("Players cache hit")
            return cached.players
        }

        do {
            let players = try await downloadPlayers()
            saveCache(PlayersCacheFile(savedAt: Date(), players: players))
            return players
        } catch {
            if let cached = loadCache() {
                print("Players fetch failed; using stale cache")
                return cached.players
            }
            throw error
        }
    }

    private func downloadPlayers() async throws -> [String: PlayersInfo] {
        let data = try await SleeperClient.data(from: try SleeperClient.url(SleeperClient.apiRoot, path: "players/nfl"))

        do {
            let decoded = try await Task.detached(priority: .userInitiated) {
                try Self.decodePlayers(from: data)
            }.value

            var players = decoded
            for (id, var player) in players {
                if player.playerID.isEmpty {
                    player.playerID = id
                    players[id] = player
                }
            }

            print("JSON Players decode successful")
            return players
        } catch {
            print(error)
            throw PlayersControllerError.decodingFailed
        }
    }

    func fetchPlayer(id: String) async throws -> PlayersInfo {
        var player: PlayersInfo = try await SleeperClient.get("players/nfl/\(id)")
        if player.playerID.isEmpty {
            player.playerID = id
        }
        return player
    }

    private static func decodePlayers(from data: Data) throws -> [String: PlayersInfo] {
        if let players = try? JSONDecoder().decode([String: PlayersInfo].self, from: data) {
            return players
        }

        let boxed = try JSONDecoder().decode([String: LossyPlayer].self, from: data)
        return boxed.reduce(into: [:]) { result, item in
            if var player = item.value.player {
                if player.playerID.isEmpty {
                    player.playerID = item.key
                }
                result[item.key] = player
            }
        }
    }

    private struct LossyPlayer: Decodable {
        var player: PlayersInfo?
        init(from decoder: Decoder) throws {
            player = try? PlayersInfo(from: decoder)
        }
    }

    private func isStale(_ savedAt: Date) -> Bool {
        Date().timeIntervalSince(savedAt) >= 24 * 60 * 60
    }

    private func loadCache() -> PlayersCacheFile? {
        guard let data = try? Data(contentsOf: cacheURL) else {
            return nil
        }
        return try? JSONDecoder().decode(PlayersCacheFile.self, from: data)
    }

    private func saveCache(_ cache: PlayersCacheFile) {
        do {
            try FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(cache)
            try data.write(to: cacheURL, options: .atomic)
        } catch {
            print("Players cache save failed: \(error.localizedDescription)")
        }
    }

    private var cacheDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Draft", isDirectory: true)
    }

    private var cacheURL: URL {
        cacheDirectory.appendingPathComponent("sleeper-players-v3.json")
    }
}
