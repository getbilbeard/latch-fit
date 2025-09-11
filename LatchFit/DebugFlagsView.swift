import SwiftUI

// A small, hidden long-press trigger at bottom-right; not overlapping nav buttons
struct DebugPanelTrigger: ViewModifier {
    @State private var showDebug = false

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottomTrailing) {
                Color.clear
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.7)
                            .onEnded { _ in showDebug = true }
                    )
                    .padding(6)
            }
            .sheet(isPresented: $showDebug) {
                DebugFlagsView()
            }
    }
}

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
