import Foundation
import SwiftData

/// Format elapsed seconds into mm:ss string.
public func formatElapsed(_ seconds: Int) -> String {
    let m = seconds / 60
    let s = seconds % 60
    return String(format: "%02d:%02d", m, s)
}

/// Close the last open interval in-place if any.
public func closeOpenInterval(_ ivs: inout [MilkInterval], at: Date = .init()) {
    if let i = ivs.lastIndex(where: { $0.end == nil }) {
        ivs[i].end = at
    }
}

/// Append a new open interval starting at `start`.
public func startInterval(_ ivs: inout [MilkInterval], at: Date = .init()) {
    ivs.append(MilkInterval(start: at, end: nil))
}

/// Summarize today's total nursing and pumping durations (in seconds)
/// for the given mom profile.
public func todayTotals(for mom: MomProfile?, sessions: [MilkSession], now: Date = Date()) -> (nurse: Int, pump: Int) {
    let cal = Calendar.current
    let todays = sessions.filter { session in
        guard session.mom?.id == mom?.id else { return false }
        return cal.isDate(session.start, inSameDayAs: now)
    }
    let nurse = todays.filter { $0.mode == .nurse }.map(\.durationSec).reduce(0, +)
    let pump = todays.filter { $0.mode == .pump }.map(\.durationSec).reduce(0, +)
    return (nurse, pump)
}

