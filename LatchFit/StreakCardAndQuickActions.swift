import SwiftUI
import SwiftData

struct StreakCard: View {
    @Environment(\.modelContext) private var context
    var body: some View {
        let s = ActivityTracker.streak(in: context)
        return Card {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Streak").font(.headline)
                    Text("\(s) day\(s == 1 ? "" : "s") in a row 🎉")
                        .font(.title3.weight(.semibold)).monospacedDigit()
                    Text("Log anything today to keep it going.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: s >= 7 ? "flame.fill" : "flame")
                    .font(.largeTitle).foregroundStyle(s >= 7 ? .orange : .secondary)
            }
        }
    }
}

struct QuickActionsRow: View {
    var addWater: () -> Void
    var addWet: () -> Void
    var addDirty: () -> Void
    var scanLabel: () -> Void
    var body: some View {
        HStack(spacing: 12) {
            CapsuleButton(title: "+8 oz", systemName: "drop.fill") { addWater() }
            CapsuleButton(title: "Wet", systemName: "drop") { addWet() }
            CapsuleButton(title: "Dirty", systemName: "trash.fill") { addDirty() }
            CapsuleButton(title: "Scan", systemName: "viewfinder") { scanLabel() }
        }
    }
}

