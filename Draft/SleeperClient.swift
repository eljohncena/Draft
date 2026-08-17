//
//  SleeperClient.swift
//  Draft
//
//  Created by John Chavez on 8/17/26.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

enum SleeperClient {
    static let apiRoot = "https://api.sleeper.app/v1"
    static let cdnRoot = "https://sleepercdn.com"

    enum Failure: Error, LocalizedError {
        case badURL
        case httpStatus(Int)
        case decoding(Error)

        var errorDescription: String? {
            switch self {
            case .badURL:
                return "Bad Sleeper URL"
            case .httpStatus(let code):
                return "Sleeper HTTP \(code)"
            case .decoding(let error):
                return error.localizedDescription
            }
        }
    }

    static func get<T: Decodable>(_ path: String) async throws -> T {
        let data = try await data(from: try url(apiRoot, path: path))
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw Failure.decoding(error)
        }
    }

    static func data(from url: URL) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse else {
            throw Failure.httpStatus(-1)
        }
        guard http.statusCode == 200 else {
            throw Failure.httpStatus(http.statusCode)
        }
        return data
    }

    static func postJSON(_ url: URL, body: [String: Any]) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        let code = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard code == 200 else {
            throw Failure.httpStatus(code)
        }
        return data
    }

    static func url(_ root: String, path: String) throws -> URL {
        let encoded = path
            .split(separator: "/")
            .map { String($0).addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? String($0) }
            .joined(separator: "/")
        guard let url = URL(string: "\(root)/\(encoded)") else {
            throw Failure.badURL
        }
        return url
    }
}

#if canImport(UIKit)
enum AvatarCache {
    private static let memory = NSCache<NSString, UIImage>()

    static func image(customURL: String, sleeperID: String, displayName: String) async -> UIImage {
        let key = "\(customURL)|\(sleeperID)|\(displayName)" as NSString
        if let cached = memory.object(forKey: key) {
            return cached
        }

        for url in candidateURLs(customURL: customURL, sleeperID: sleeperID) {
            if let data = try? await SleeperClient.data(from: url),
               let image = UIImage(data: data) {
                memory.setObject(image, forKey: key)
                return image
            }
        }

        let placeholder = initialsImage(displayName)
        memory.setObject(placeholder, forKey: key)
        return placeholder
    }

    static func placeholder(_ displayName: String) -> UIImage {
        initialsImage(displayName)
    }

    private static func candidateURLs(customURL: String, sleeperID: String) -> [URL] {
        var urls: [URL] = []
        if customURL.hasPrefix("http"), let url = URL(string: customURL) {
            urls.append(url)
        }

        let id: String
        if !sleeperID.isEmpty {
            id = sleeperID
        } else if !customURL.isEmpty && !customURL.hasPrefix("http") {
            id = customURL
        } else {
            id = ""
        }

        if !id.isEmpty {
            if let thumb = URL(string: "\(SleeperClient.cdnRoot)/avatars/thumbs/\(id)") {
                urls.append(thumb)
            }
            if let full = URL(string: "\(SleeperClient.cdnRoot)/avatars/\(id)") {
                urls.append(full)
            }
        }
        return urls
    }

    private static func initialsImage(_ name: String) -> UIImage {
        #if os(watchOS)
        return UIImage(systemName: "person.crop.circle.fill") ?? UIImage()
        #else
        let initials = initials(from: name)
        let size = CGSize(width: 128, height: 128)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            UIColor.secondarySystemFill.setFill()
            UIBezierPath(ovalIn: CGRect(origin: .zero, size: size)).fill()

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 48, weight: .semibold),
                .foregroundColor: UIColor.label
            ]
            let text = initials as NSString
            let textSize = text.size(withAttributes: attributes)
            let point = CGPoint(x: (size.width - textSize.width) / 2, y: (size.height - textSize.height) / 2)
            text.draw(at: point, withAttributes: attributes)
        }
        #endif
    }

    private static func initials(from name: String) -> String {
        let parts = name.split(separator: " ").prefix(2)
        let letters = parts.compactMap { $0.first.map(String.init) }
        let value = letters.joined().uppercased()
        return value.isEmpty ? "?" : value
    }
}
#endif
