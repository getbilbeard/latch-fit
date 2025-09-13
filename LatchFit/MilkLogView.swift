import SwiftUI
import SwiftData

/// Main milk log view with dual timers and today's history.
struct MilkLogView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var activeProfileStore: ActiveProfileStore
    @Query(sort: [SortDescriptor(\MomProfile.createdAt, order: .reverse)])
    private var profiles: [MomProfile]
    @Query(sort: [SortDescriptor(\MilkSession.startedAt, order: .reverse)])
    private var allSessions: [MilkSession]

    @State private var showCalendar = false

    private var activeMom: MomProfile? {
        profiles.first { $0.id.uuidString == activeProfileStore.activeProfileID }
    }

    private var todaySessions: [MilkSession] {
        let cal = Calendar.current
        return allSessions.filter { session in
            guard session.mom?.id == activeMom?.id else { return false }
            return cal.isDate(session.start, inSameDayAs: Date())
        }
    }

    private var nurseTotal: Int {
        todaySessions.filter { $0.mode == .nurse }.map(\.durationSec).reduce(0, +)
    }
    private var pumpTotal: Int {
        todaySessions.filter { $0.mode == .pump }.map(\.durationSec).reduce(0, +)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    MilkTimerPanels()
                    todayList
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .navigationTitle("Milk")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Calendar") { showCalendar = true }
                }
            }
            .sheet(isPresented: $showCalendar) { MilkMonthView() }
            .background(LF.bg.ignoresSafeArea())
        }
    }

    // MARK: - Today list
    private var todayList: some View {
        Card {
            CardHeader(title: "Today")
            if todaySessions.isEmpty {
                Text("No sessions yet.")
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 0) {
                    ForEach(todaySessions) { s in
                        HStack(spacing: 8) {
                            Text(s.side == .left ? "Left" : "Right")
                            Text("•")
                            Text(s.mode == .nurse ? "Nurse" : "Pump")
                            Spacer()
                            Text(durationString(s.durationSec))
                                .monospacedDigit()
                            Text("•")
                            Text(timeOnly(s.start))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 6)
                        if s.id != todaySessions.last?.id {
                            Divider().opacity(0.15)
                        }
                    }
                }
                Divider().opacity(0.15).padding(.top, 8)
                HStack {
                    Text("Nurse \(durationString(nurseTotal))")
                    Spacer()
                    Text("Pump \(durationString(pumpTotal))")
                }
                .font(.footnote)
                .padding(.top, 4)
            }
        }
    }

    private func durationString(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%dm %02ds", m, s)
    }

    private func timeOnly(_ d: Date) -> String {
        let f = DateFormatter(); f.timeStyle = .short; return f.string(from: d)
    }
}

#Preview {
    MilkLogView()
        .environmentObject(ActiveProfileStore())
}
