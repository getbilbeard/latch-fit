import SwiftUI
import SwiftData

struct ProfilesManagerView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var activeProfileStore: ActiveProfileStore
    @Query(sort: [SortDescriptor(\MomProfile.createdAt, order: .reverse)]) private var profiles: [MomProfile]
    @State private var showAddProfile = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(profiles) { p in
                    HStack {
                        Text(p.momName)
                        Spacer()
                        Button("Use this profile") {
                            activeProfileStore.setActive(p.id.uuidString)
                            dismiss()
                        }
                    }
                }

                Button("Add new profile") { showAddProfile = true }
            }
            .navigationTitle("Profiles")
        }
        .sheet(isPresented: $showAddProfile) {
            OnboardingMomProfileView()
        }
    }
}
