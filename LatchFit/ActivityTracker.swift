import Foundation
import SwiftData

// MARK: - Daily Activity (streaks)
@Model final class DailyActivity {
    @Attribute(.unique) var date: Date // startOfDay
    var didWater: Bool
    var didMeal: Bool
    var didMilk: Bool
    var didDiaper: Bool

    init(date: Date = Calendar.current.startOfDay(for: .now),
         didWater: Bool = false, didMeal: Bool = false, didMilk: Bool = false, didDiaper: Bool = false) {
        self.date = Calendar.current.startOfDay(for: date)
        self.didWater = didWater
        self.didMeal = didMeal
        self.didMilk = didMilk
        self.didDiaper = didDiaper
    }
}

enum ActivityKind { case water, meal, milk, diaper }

struct ActivityTracker {
    static func today(in context: ModelContext) -> DailyActivity {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end = cal.date(byAdding: .day, value: 1, to: start)!
        let pred = #Predicate<DailyActivity> { $0.date >= start && $0.date < end }
        if let first = try? context.fetch(FetchDescriptor(predicate: pred)).first { return first }
        let rec = DailyActivity(date: start)
        context.insert(rec)
        try? context.save()
        return rec
    }

    static func mark(_ kind: ActivityKind, in context: ModelContext) {
        let rec = today(in: context)
        switch kind {
        case .water:  rec.didWater  = true
        case .meal:   rec.didMeal   = true
        case .milk:   rec.didMilk   = true
        case .diaper: rec.didDiaper = true
        }
        try? context.save()
    }

    static func streak(in context: ModelContext) -> Int {
        let cal = Calendar.current
        let all = (try? context.fetch(FetchDescriptor<DailyActivity>(sortBy: [.init(\DailyActivity.date, order: .reverse)]))) ?? []
        var d = cal.startOfDay(for: Date())
        var s = 0
        var i = 0
        while i < all.count {
            let day = all[i]
            let start = cal.startOfDay(for: day.date)
            if start == d, (day.didWater || day.didMeal || day.didMilk || day.didDiaper) {
                s += 1; d = cal.date(byAdding: .day, value: -1, to: d)!; i += 1
            } else if start > d { i += 1 } else { break }
        }
        return s
    }
}//
//  ActivityTracker.swift
//  LatchFit
//
//  Created by Proxy on 9/8/25.
//

