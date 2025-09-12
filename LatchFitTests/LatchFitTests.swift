//
//  LatchFitTests.swift
//  LatchFitTests
//
//  Created by Proxy on 9/7/25.
//

import Testing
@testable import LatchFit

struct LatchFitTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

    @Test func onboardingLogic() throws {
        #expect(needsOnboarding(profileCount: 0, hasCompletedOnboarding: false))
        #expect(needsOnboarding(profileCount: 1, hasCompletedOnboarding: false))
        #expect(needsOnboarding(profileCount: 0, hasCompletedOnboarding: true))
        #expect(!needsOnboarding(profileCount: 1, hasCompletedOnboarding: true))
    }

}
