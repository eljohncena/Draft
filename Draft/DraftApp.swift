//
//  DraftApp.swift
//  Draft
//
//  Created by John Chavez on 8/30/23.
//

import SwiftUI
import CoreData

@main
struct DraftApp: App {
    @Environment(\.scenePhase) private var scenePhase
    private let persistence = PersistenceController.shared

    init() {
        #if os(iOS)
        GameDayRefresh.register()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.managedObjectContext, persistence.container.viewContext)
                .onAppear {
                    WatchBridge.shared.activate()
                    #if os(iOS)
                    LeagueAlertCenter.shared.activate()
                    GameDayRefresh.schedule()
                    #endif
                }
        }
        .onChange(of: scenePhase) { _, phase in
            #if os(iOS)
            if phase == .active {
                GameDayRefresh.schedule()
            }
            #endif
        }
    }
}

private struct RootView: View {
    @AppStorage("sleeperDidOnboard", store: AppGroup.defaults) private var didOnboard = false

    var body: some View {
        if didOnboard {
            ContentView()
        } else {
            LandingView {
                didOnboard = true
            }
        }
    }
}
