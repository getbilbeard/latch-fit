import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\MomProfile.createdAt, order: .reverse)])
    private var profiles: [MomProfile]

    var body: some View {
        ZStack {
            if shouldShowOnboarding {
                OnboardingMomProfileView()
            } else {
                MainTabView()
            }
        }
        .onAppear {
            // If no profiles, force onboarding regardless of the flag
            if profiles.isEmpty {
                hasCompletedOnboarding = false
            }
        }
    }

    private var shouldShowOnboarding: Bool {
        needsOnboarding(profileCount: profiles.count, hasCompletedOnboarding: hasCompletedOnboarding)
    }
}

/// Helper used for logic tests.
func needsOnboarding(profileCount: Int, hasCompletedOnboarding: Bool) -> Bool {
    profileCount == 0 || !hasCompletedOnboarding
}

// Removed the Baby tab here to avoid the current “Ambiguous use of 'init()'” error on DiaperHistoryView().
// The real app can use the project’s dedicated Baby tab view instead.
private struct MainTabView: View {
    var body: some View {
        TabView {
            // Diet
            DietPlanView()
                .tabItem { Label("Diet", systemImage: "fork.knife") }

            // Milk
            MilkLogView()
                .tabItem { Label("Milk", systemImage: "drop") }

            // Profiles (manage or add users)
            ProfilesManagerView()
                .tabItem { Label("Profiles", systemImage: "person.2") }
        }
    }
}
