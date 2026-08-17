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
            ContentView()
                .environment(\.managedObjectContext, persistence.container.viewContext)
                .onAppear {
                    WatchBridge.shared.activate()
                    #if os(iOS)
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
