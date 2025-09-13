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

    /// Persist the last selected mode between launches.
    @AppStorage("MilkTimerMode") private var modeRaw: String = MilkSession.Mode.nurse.rawValue
    private var modeBinding: Binding<MilkSession.Mode> {
        Binding(get: { MilkSession.Mode(rawValue: modeRaw) ?? .nurse },
                set: { modeRaw = $0.rawValue })
    }
    private var selectedMode: MilkSession.Mode { MilkSession.Mode(rawValue: modeRaw) ?? .nurse }

    // Timer state for each side
    struct TimerState {
        var intervals: [MilkInterval] = []
        var isRunning = false
        var isPaused = false
        var lastStart: Date? = nil
        var durationSec: Int {
            let closed = intervals.compactMap { iv -> Int? in
                guard let end = iv.end else { return nil }
                return Int(end.timeIntervalSince(iv.start))
            }.reduce(0, +)
            if let live = lastStart, isRunning {
                return closed + Int(Date().timeIntervalSince(live))
            }
            return closed
        }
    }

    @State private var leftSession = TimerState()
    @State private var rightSession = TimerState()
    @State private var showCalendar = false
    @State private var showNoProfileAlert = false
    @State private var toastText: String? = nil
    @Environment(\.scenePhase) private var scenePhase

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

    private var totals: (nurse: Int, pump: Int) {
        todayTotals(for: activeMom, sessions: allSessions)
    }
    private var nurseTotal: Int { totals.nurse }
    private var pumpTotal: Int { totals.pump }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    MilkTimerPanels(left: $leftSession,
                                    right: $rightSession,
                                    mode: modeBinding,
                                    start: start,
                                    pause: pause,
                                    resume: resume,
                                    stop: stopAndLog)
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
        .overlay(alignment: .top) {
            if let toastText {
                Toast(text: toastText)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .alert("No Active Profile", isPresented: $showNoProfileAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Please add or select a profile before logging.")
        }
        .onChange(of: scenePhase) { phase in
            if phase == .background {
                if leftSession.isRunning { closeOpenInterval(&leftSession.intervals) }
                if rightSession.isRunning { closeOpenInterval(&rightSession.intervals) }
            } else if phase == .active {
                if leftSession.isRunning {
                    leftSession.lastStart = Date(); startInterval(&leftSession.intervals, at: leftSession.lastStart!)
                }
                if rightSession.isRunning {
                    rightSession.lastStart = Date(); startInterval(&rightSession.intervals, at: rightSession.lastStart!)
                }
            }
        }
    }

    // MARK: - Actions
    private func start(_ side: MilkSession.Side) {
        guard activeMom != nil else { showNoProfileAlert = true; return }
        let now = Date()
        switch side {
        case .left:
            guard !leftSession.isRunning else { return }
            leftSession.isRunning = true
            leftSession.isPaused = false
            leftSession.lastStart = now
            startInterval(&leftSession.intervals, at: now)
        case .right:
            guard !rightSession.isRunning else { return }
            rightSession.isRunning = true
            rightSession.isPaused = false
            rightSession.lastStart = now
            startInterval(&rightSession.intervals, at: now)
        }
    }

    private func pause(_ side: MilkSession.Side) {
        let now = Date()
        switch side {
        case .left:
            guard leftSession.isRunning, !leftSession.isPaused else { return }
            leftSession.isPaused = true
            leftSession.isRunning = false
            closeOpenInterval(&leftSession.intervals, at: now)
            leftSession.lastStart = nil
        case .right:
            guard rightSession.isRunning, !rightSession.isPaused else { return }
            rightSession.isPaused = true
            rightSession.isRunning = false
            closeOpenInterval(&rightSession.intervals, at: now)
            rightSession.lastStart = nil
        }
    }

    private func resume(_ side: MilkSession.Side) {
        let now = Date()
        switch side {
        case .left:
            guard leftSession.isPaused else { return }
            leftSession.isPaused = false
            leftSession.isRunning = true
            leftSession.lastStart = now
            startInterval(&leftSession.intervals, at: now)
        case .right:
            guard rightSession.isPaused else { return }
            rightSession.isPaused = false
            rightSession.isRunning = true
            rightSession.lastStart = now
            startInterval(&rightSession.intervals, at: now)
        }
    }

    private func stopAndLog(_ side: MilkSession.Side) {
        guard let mom = activeMom else { showNoProfileAlert = true; return }
        let now = Date()
        switch side {
        case .left:
            closeOpenInterval(&leftSession.intervals, at: now)
            let snapshot = leftSession.intervals
            let session = MilkSession(mom: mom,
                                      mode: selectedMode,
                                      side: .left,
                                      intervals: snapshot)
            context.insert(session)
            try? context.save()
            showToast("Logged Left • \(selectedMode == .nurse ? "Nurse" : "Pump") • \(session.durationSec/60)m • \(timeOnly(now))")
            leftSession = TimerState()
        case .right:
            closeOpenInterval(&rightSession.intervals, at: now)
            let snapshot = rightSession.intervals
            let session = MilkSession(mom: mom,
                                      mode: selectedMode,
                                      side: .right,
                                      intervals: snapshot)
            context.insert(session)
            try? context.save()
            showToast("Logged Right • \(selectedMode == .nurse ? "Nurse" : "Pump") • \(session.durationSec/60)m • \(timeOnly(now))")
            rightSession = TimerState()
        }
    }

    private func showToast(_ text: String) {
        withAnimation { toastText = text }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { toastText = nil }
        }
        bump()
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

#if DEBUG
extension MilkLogView.TimerState {
    /// Non-persisted, safe value for SwiftUI previews.
    static let preview: MilkLogView.TimerState = {
        MilkLogView.TimerState(
            intervals: [],
            isRunning: false,
            isPaused: false,
            lastStart: nil
        )
    }()
}
#endif

#Preview {
    MilkLogView()
        .environmentObject(ActiveProfileStore())
}
