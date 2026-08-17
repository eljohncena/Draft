//
//  DraftWatchApp.swift
//  DraftWatch
//
//  Created by John Chavez on 8/17/26.
//

import SwiftUI

@main
struct DraftWatchApp: App {
    init() {
        WatchBridge.shared.activate()
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                WatchRankView()
            }
        }
    }
}
