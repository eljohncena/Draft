//
//  WatchBridge.swift
//  Draft
//
//  Created by John Chavez on 8/17/26.
//

import Foundation
#if canImport(WatchConnectivity)
import WatchConnectivity
#endif
#if canImport(WidgetKit)
import WidgetKit
#endif

final class WatchBridge: NSObject {
    static let shared = WatchBridge()

    func activate() {
        #if canImport(WatchConnectivity)
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
        #endif
    }

    func push(_ snapshot: RankWidgetSnapshot) {
        #if os(iOS) && canImport(WatchConnectivity)
        activate()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(snapshot) else { return }
        let payload: [String: Any] = [
            "snapshot": data,
            "myUserID": AppGroup.myUserID,
            "leagueID": snapshot.leagueID
        ]
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        try? session.updateApplicationContext(payload)
        if session.isComplicationEnabled {
            session.transferCurrentComplicationUserInfo(payload)
        }
        #endif
    }
}

#if canImport(WatchConnectivity)
extension WatchBridge: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error {
            print("Watch session failed: \(error.localizedDescription)")
        }
        #if os(watchOS)
        if activationState == .activated {
            consume(session.receivedApplicationContext)
        }
        #endif
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        consume(applicationContext)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        consume(userInfo)
    }

    private func consume(_ context: [String: Any]) {
        #if os(watchOS)
        guard let data = context["snapshot"] as? Data else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let snapshot = try? decoder.decode(RankWidgetSnapshot.self, from: data) else { return }
        if let leagueID = context["leagueID"] as? String, !leagueID.isEmpty {
            SleeperConfig.leagueID = leagueID
        } else if !snapshot.leagueID.isEmpty {
            SleeperConfig.leagueID = snapshot.leagueID
        }
        if let myUserID = context["myUserID"] as? String, !myUserID.isEmpty {
            AppGroup.myUserID = myUserID
        }
        RankWidgetCache.write(snapshot)
        #endif
    }
}
#endif
