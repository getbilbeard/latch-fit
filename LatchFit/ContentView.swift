import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var activeProfileStore: ActiveProfileStore
    @Query(sort: [SortDescriptor(\MomProfile.createdAt, order: .reverse)])
    private var profiles: [MomProfile]
    @State private var showProfilePicker = false

    var body: some View {
        let base = ZStack {
            if shouldShowOnboarding {
                OnboardingMomProfileView()
            } else {
                MainTabView()
            }
        }
        .sheet(isPresented: $showProfilePicker) {
            ProfilesManagerView()
                .interactiveDismissDisabled()
        }
        .onAppear { evaluateProfileStatus() }

        if #available(iOS 17.0, *) {
            base
                .onChange(of: profiles.count, initial: false) { _, _ in evaluateProfileStatus() }
                .onChange(of: activeProfileStore.activeProfileID, initial: false) { _, _ in evaluateProfileStatus() }
        } else {
            base
                .onChange(of: profiles.count) { _ in evaluateProfileStatus() }
                .onChange(of: activeProfileStore.activeProfileID) { _ in evaluateProfileStatus() }
        }
    }

    private var shouldShowOnboarding: Bool {
        profiles.isEmpty || !hasCompletedOnboarding
    }

    private func evaluateProfileStatus() {
        if profiles.isEmpty {
            hasCompletedOnboarding = false
            showProfilePicker = false
        } else if let id = activeProfileStore.activeProfileID,
                  profiles.contains(where: { $0.id.uuidString == id }) {
            showProfilePicker = false
        } else {
            showProfilePicker = true
        }
    }
}

/// Helper used for logic tests.
func needsOnboarding(profileCount: Int, hasCompletedOnboarding: Bool) -> Bool {
    profileCount == 0 || !hasCompletedOnboarding
}

private struct MainTabView: View {
    var body: some View {
        TabView {
            // Diet
            NutritionDashboardView()
                .tabItem { Label("Diet", systemImage: "fork.knife") }

            // Milk
            MilkLogView()
                .tabItem { Label("Milk", systemImage: "drop") }

            // Baby
            BabyView()
                .tabItem { Label("Baby", systemImage: "figure.and.child.holdinghands") }

            // Profiles (manage or add users)
            ProfilesManagerView()
                .tabItem { Label("Profiles", systemImage: "person.2") }
        }
        .tint(Color.lfSageDeep)
    }
}
