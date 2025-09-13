import Foundation
import Testing
@testable import LatchFit

struct MilkTimerTests {
    @Test func durationAccumulates() {
        let start = Date()
        let interval1 = MilkInterval(start: start, end: start.addingTimeInterval(60))
        let interval2 = MilkInterval(start: start.addingTimeInterval(120), end: start.addingTimeInterval(180))
        let session = MilkSession(mom: nil, mode: .nurse, side: .left, intervals: [interval1, interval2])
        #expect(session.durationSec == 120)
    }
}
