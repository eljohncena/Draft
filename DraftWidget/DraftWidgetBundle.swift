//
//  DraftWidgetBundle.swift
//  DraftWidget
//
//  Created by John Chavez on 8/17/26.
//

import SwiftUI
import WidgetKit

@main
struct DraftWidgetBundle: WidgetBundle {
    var body: some Widget {
        RankWidget()
        MatchupWidget()
        StatsWidget()
        StandingsWidget()
        #if os(iOS) && !targetEnvironment(macCatalyst) && canImport(ActivityKit)
        MatchupLiveActivityWidget()
        #endif
    }
}
