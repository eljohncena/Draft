//
//  MatchupController.swift
//  Draft
//
//  Created by John Chavez on 9/12/23.
//

import Foundation
import SwiftUI

class MatchupsController {
    
    enum MatchupsControllerError: Error, LocalizedError {
        case itemNotFound
        case decodingFailed
        
    }
    
    func fetchMatchupsInfo(week: Int) async throws -> [MatchupsInfo] {
        try await SleeperClient.get("league/\(SleeperConfig.leagueID)/matchups/\(week)")
    }

    
}

class NewsController {

    enum NewsControllerError: Error {
        case itemNotFound
        case decodingFailed
    }

    private static var nflCache: (fetchedAt: Date, items: [NewsItem])?
    private static let cacheDuration: TimeInterval = 15 * 60

    func fetchNFLNews() async throws -> [NewsItem] {
        if let cache = Self.nflCache, Date().timeIntervalSince(cache.fetchedAt) < Self.cacheDuration {
            return cache.items
        }

        // ESPN's CDN returns 403 to CFNetwork/Safari user agents. JSON still has
        // team/player tags, so try that with a client UA first, then RSS.
        let items: [NewsItem]
        if let jsonItems = await fetchESPNJSON(), !jsonItems.isEmpty {
            items = jsonItems
        } else {
            items = (try? await fetchESPNRSS()) ?? []
        }

        guard !items.isEmpty else {
            throw NewsControllerError.itemNotFound
        }

        Self.nflCache = (Date(), items)
        return items
    }

    private func fetchESPNJSON() async -> [NewsItem]? {
        guard let url = URL(string: "https://site.api.espn.com/apis/site/v2/sports/football/nfl/news?limit=50") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.setValue("okhttp/4.12.0", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            guard code == 200 else { return nil }
            let feed = try JSONDecoder().decode(ESPNNewsFeed.self, from: data)
            let items = feed.articles.map(\.newsItem)
            return items.isEmpty ? nil : items
        } catch {
            print("ESPN JSON news failed: \(error.localizedDescription)")
            return nil
        }
    }

    private func fetchESPNRSS() async throws -> [NewsItem] {
        guard let url = URL(string: "https://www.espn.com/espn/rss/nfl/news") else {
            throw NewsControllerError.itemNotFound
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        let code = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard code == 200 else {
            throw NewsControllerError.itemNotFound
        }

        let items = ESPNRSSParser.parse(data)
        guard !items.isEmpty else {
            throw NewsControllerError.decodingFailed
        }
        return items
    }

    func fetchPlayerNews(playerID: String) async throws -> [NewsItem] {
        let safeID = playerID.filter { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "-" }
        guard !safeID.isEmpty else { return [] }

        let query = """
        query {
          news: get_player_news(sport: "nfl", player_id: "\(safeID)", limit: 12) {
            metadata
            player_id
            published
            source
          }
        }
        """

        let data: Data
        do {
            data = try await SleeperClient.postJSON(
                URL(string: "https://sleeper.com/graphql")!,
                body: ["query": query]
            )
        } catch {
            throw NewsControllerError.itemNotFound
        }

        do {
            let envelope = try JSONDecoder().decode(SleeperNewsEnvelope.self, from: data)
            return (envelope.data?.news ?? []).map { $0.newsItem(fallbackPlayerID: safeID) }
        } catch {
            print(error)
            throw NewsControllerError.decodingFailed
        }
    }

    func fetchNews(forPlayerIDs playerIDs: [String]) async -> [NewsItem] {
        await withTaskGroup(of: [NewsItem].self) { group in
            for id in playerIDs {
                group.addTask { [weak self] in
                    guard let self else { return [] }
                    return (try? await self.fetchPlayerNews(playerID: id)) ?? []
                }
            }

            var items: [NewsItem] = []
            var seen = Set<String>()
            for await batch in group {
                for item in batch where seen.insert(item.id).inserted {
                    items.append(item)
                }
            }
            return items.sorted { ($0.published ?? .distantPast) > ($1.published ?? .distantPast) }
        }
    }
}

private struct FailableDecodable<T: Decodable>: Decodable {
    var value: T?
    init(from decoder: Decoder) throws {
        value = try? T(from: decoder)
    }
}

private struct ESPNNewsFeed: Decodable {
    var articles: [ESPNNewsArticle] = []

    enum CodingKeys: String, CodingKey {
        case articles
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let wrapped = try container.decodeIfPresent([FailableDecodable<ESPNNewsArticle>].self, forKey: .articles) ?? []
        articles = wrapped.compactMap(\.value)
    }
}

private struct ESPNNewsArticle: Decodable {
    var id: String
    var headline: String
    var description: String
    var published: Date?
    var byline: String
    var imageURL: URL?
    var webURL: URL?
    var playerNames: [String]
    var teams: [String]

    var newsItem: NewsItem {
        NewsItem(
            id: "espn-\(id)",
            title: headline,
            summary: description,
            source: byline.isEmpty ? "ESPN" : byline,
            url: webURL,
            published: published,
            imageURL: imageURL,
            playerNames: playerNames,
            teams: teams
        )
    }

    enum CodingKeys: String, CodingKey {
        case id, headline, description, published, byline, images, categories, links
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let value = try? container.decode(String.self, forKey: .id) {
            id = value
        } else if let value = try? container.decode(Int.self, forKey: .id) {
            id = String(value)
        } else {
            id = UUID().uuidString
        }
        headline = try container.decodeIfPresent(String.self, forKey: .headline) ?? ""
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        if let date = try? container.decode(Date.self, forKey: .published) {
            published = date
        } else if let string = try container.decodeIfPresent(String.self, forKey: .published) {
            published = ISO8601DateFormatter().date(from: string)
        } else {
            published = nil
        }
        byline = try container.decodeIfPresent(String.self, forKey: .byline) ?? ""

        let images = try container.decodeIfPresent([ESPNImage].self, forKey: .images) ?? []
        imageURL = images.first { $0.type == "header" }?.url ?? images.first?.url

        let links = try container.decodeIfPresent(ESPNLinks.self, forKey: .links)
        webURL = links?.web?.href.flatMap(URL.init(string:))

        let categories = try container.decodeIfPresent([ESPNCategory].self, forKey: .categories) ?? []
        playerNames = categories.compactMap(\.athleteName)
        teams = categories.compactMap(\.teamAbbreviation)
    }
}

private struct ESPNImage: Decodable {
    var type: String?
    var url: URL?

    enum CodingKeys: String, CodingKey {
        case type, url
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        if let string = try container.decodeIfPresent(String.self, forKey: .url) {
            url = URL(string: string)
        }
    }
}

private struct ESPNLinks: Decodable {
    var web: ESPNWebLink?
}

private struct ESPNWebLink: Decodable {
    var href: String?
}

private struct ESPNCategory: Decodable {
    var type: String?
    var description: String?
    var team: ESPNTeam?
    var athlete: ESPNAthlete?

    var athleteName: String? {
        let name = athlete?.description ?? (type == "athlete" ? description : nil)
        return name?.isEmpty == false ? name : nil
    }

    var teamAbbreviation: String? {
        if let abbreviation = team?.abbreviation, !abbreviation.isEmpty {
            return abbreviation.uppercased()
        }
        return nil
    }
}

private struct ESPNTeam: Decodable {
    var abbreviation: String?
}

private struct ESPNAthlete: Decodable {
    var description: String?
}

private struct SleeperNewsEnvelope: Decodable {
    var data: SleeperNewsData?
}

private struct SleeperNewsData: Decodable {
    var news: [SleeperNewsItem]?
}

private struct SleeperNewsItem: Decodable {
    var playerID: String?
    var published: Double?
    var source: String?
    var metadata: SleeperNewsMetadata?

    enum CodingKeys: String, CodingKey {
        case playerID = "player_id"
        case published
        case source
        case metadata
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        playerID = try container.decodeIfPresent(String.self, forKey: .playerID)
        source = try container.decodeIfPresent(String.self, forKey: .source)
        metadata = try container.decodeIfPresent(SleeperNewsMetadata.self, forKey: .metadata)
        if let value = try container.decodeIfPresent(Double.self, forKey: .published) {
            published = value
        } else if let value = try container.decodeIfPresent(Int.self, forKey: .published) {
            published = Double(value)
        } else {
            published = nil
        }
    }

    func newsItem(fallbackPlayerID: String) -> NewsItem {
        let title = metadata?.title ?? "Player update"
        let summary = [metadata?.description, metadata?.analysis]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
        let publishedDate = published.map { Date(timeIntervalSince1970: $0 / 1000) }
        let id = [
            "sleeper",
            playerID ?? fallbackPlayerID,
            String(Int(published ?? 0)),
            title
        ].joined(separator: "-")

        return NewsItem(
            id: id,
            title: title,
            summary: summary,
            source: source ?? "Sleeper",
            url: metadata?.url.flatMap(URL.init(string:)),
            published: publishedDate,
            imageURL: nil,
            playerNames: [],
            teams: [],
            relatedPlayerIDs: [playerID].compactMap { $0 }.filter { !$0.isEmpty }
        )
    }
}

private struct SleeperNewsMetadata: Decodable {
    var title: String?
    var description: String?
    var analysis: String?
    var url: String?
}

private final class ESPNRSSParser: NSObject, XMLParserDelegate {
    private var items: [NewsItem] = []
    private var fields: [String: String] = [:]
    private var element = ""
    private var text = ""
    private var inItem = false

    static func parse(_ data: Data) -> [NewsItem] {
        let parser = XMLParser(data: data)
        let delegate = ESPNRSSParser()
        parser.delegate = delegate
        parser.parse()
        return delegate.items
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        element = elementName
        text = ""
        if elementName == "item" {
            inItem = true
            fields = [:]
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard inItem else { return }
        text += string
    }

    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        guard inItem, let string = String(data: CDATABlock, encoding: .utf8) else { return }
        text += string
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        if elementName == "item" {
            if let item = makeItem() {
                items.append(item)
            }
            inItem = false
            fields = [:]
            return
        }

        guard inItem else { return }
        fields[elementName] = text.trimmingCharacters(in: .whitespacesAndNewlines)
        text = ""
    }

    private func makeItem() -> NewsItem? {
        let title = fields["title"] ?? ""
        guard !title.isEmpty else { return nil }
        let guid = fields["guid"] ?? ""
        let link = fields["link"] ?? ""
        let source = fields["dc:creator"] ?? fields["creator"] ?? ""
        return NewsItem(
            id: "espn-\(guid.isEmpty ? title : guid)",
            title: title,
            summary: fields["description"] ?? "",
            source: source.isEmpty ? "ESPN" : source,
            url: URL(string: link),
            published: Self.date(from: fields["pubDate"] ?? ""),
            imageURL: nil,
            playerNames: [],
            teams: []
        )
    }

    private static func date(from raw: String) -> Date? {
        guard !raw.isEmpty else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        return formatter.date(from: raw)
    }
}
