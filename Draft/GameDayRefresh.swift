//
//  GameDayRefresh.swift
//  Draft
//
//  Created by John Chavez on 8/17/26.
//

#if os(iOS)
import BackgroundTasks
import Foundation

enum GameDayRefresh {
    static let identifier = "com.example.DraftFantasy.refresh"

    static func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: nil) { task in
            handle(task as? BGAppRefreshTask)
        }
    }

    static func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = nextDate()
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Game-day refresh schedule failed: \(error.localizedDescription)")
        }
    }

    static func nextDate(after now: Date = Date()) -> Date {
        if GameDay.isGameDay(now) {
            return now.addingTimeInterval(90 * 60)
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York") ?? .current
        for offset in 0...8 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: now) else { continue }
            guard GameDay.isGameDay(day) else { continue }
            var components = calendar.dateComponents([.year, .month, .day], from: day)
            components.hour = 10
            components.minute = 0
            if let date = calendar.date(from: components), date > now {
                return date
            }
        }
        return now.addingTimeInterval(24 * 60 * 60)
    }

    private static func handle(_ task: BGAppRefreshTask?) {
        guard let task else { return }
        schedule()

        let work = Task {
            do {
                let snapshot = try await LeagueRefresher.fetch(includeAvatars: false)
                await MainActor.run {
                    LeagueStore.save(snapshot)
                }
                task.setTaskCompleted(success: true)
            } catch {
                print("Game-day refresh failed: \(error.localizedDescription)")
                task.setTaskCompleted(success: false)
            }
        }

        task.expirationHandler = {
            work.cancel()
        }
    }
}
#endif
