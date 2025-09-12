import SwiftUI
import SwiftData

struct ProfilesManagerView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var activeProfileStore: ActiveProfileStore
    @Query(sort: [SortDescriptor(\MomProfile.createdAt, order: .reverse)]) private var profiles: [MomProfile]

    var body: some View {
        NavigationStack {
            List {
                ForEach(profiles) { p in
                    Button {
                        activeProfileStore.setActive(p.id.uuidString)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading) {
                            Text(p.momName).font(.headline)
                            Text("\(p.numberOfChildren) children • \(p.activityLevel)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .onDelete { idx in
                    for i in idx { context.delete(profiles[i]) }
                    try? context.save()
                }
            }
            .navigationTitle("Profiles")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink("Add") { OnboardingMomProfileView() }
                }
            }
        }
    }
}//
//  ProfilesManagerView.swift
//  LatchFit
//
//  Created by Proxy on 9/8/25.
//

