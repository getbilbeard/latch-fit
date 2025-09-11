// FeatureFlags.swift
import SwiftUI

/// Runtime-tunable flags for prelaunch/testing.
/// Stored with @AppStorage so toggles persist between launches.
@MainActor
final class FeatureFlags: ObservableObject {
    // Data sources
    @AppStorage("flags.useLiveRecipes") var useLiveRecipes: Bool = true
    @AppStorage("flags.useMockRecipes") var useMockRecipes: Bool = false

    // AI gate
    @AppStorage("flags.aiEnabled") var aiEnabled: Bool = true

    // Fault injection
    @AppStorage("flags.simulateQuotaExhausted") var simulateQuotaExhausted: Bool = false
    @AppStorage("flags.simulateNetworkFailure") var simulateNetworkFailure: Bool = false

    func reset() {
        useLiveRecipes = true
        useMockRecipes = false
        aiEnabled = true
        simulateQuotaExhausted = false
        simulateNetworkFailure = false
        objectWillChange.send()
    }
}
