import SwiftUI

#if DEBUG

struct DebugFlagsView: View {
    @EnvironmentObject var flags: FeatureFlags

    var body: some View {
        NavigationStack {
            Form {
                Section("AI & Data Sources") {
                    Toggle("AI Enabled", isOn: $flags.aiEnabled)
                    Toggle("Use Live Recipes", isOn: $flags.useLiveRecipes)
                    Toggle("Use Mock Recipes", isOn: $flags.useMockRecipes)
                }
                Section("Fault Injection") {
                    Toggle("Simulate Quota Exhausted", isOn: $flags.simulateQuotaExhausted)
                    Toggle("Simulate Network Failure", isOn: $flags.simulateNetworkFailure)
                }
                Section {
                    Button("Reset to Defaults") { flags.reset() }
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle("Debug Flags")
        }
    }
}

#endif
