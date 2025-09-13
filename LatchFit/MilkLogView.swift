import SwiftUI
import SwiftData

struct MilkLogView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var activeProfileStore: ActiveProfileStore
    @Query(sort: [SortDescriptor(\MomProfile.createdAt, order: .reverse)]) private var profiles: [MomProfile]
    @Query(sort: [SortDescriptor(\MilkSession.startedAt, order: .reverse)]) private var allMilkSessions: [MilkSession]

    // All sessions, newest first
    @Query(sort: [SortDescriptor(\PumpSession.date, order: .reverse)])
    private var allSessions: [PumpSession]

    // Quick log
    @State private var volume = ""
    private typealias BreastSide = PumpSession.BreastSide
    @State private var selectedSide: BreastSide = .both
    @State private var showConfetti = false

    // Stopwatch state
    @State private var isTiming = false
    @State private var timerStart: Date? = nil
    @State private var elapsed: TimeInterval = 0
    @State private var snaps: [TimerSnap] = []   // today’s timer snapshots only
    @State private var currentSession: MilkSession? = nil

    @State private var selectedMode = "nursing"
    @State private var showOzSheet = false
    @State private var ozInput = ""
    @State private var pendingSession: PumpSession? = nil

    // Today-only view (computed from allSessions)
    private var todaySessions: [PumpSession] {
        let cal = Calendar.current
        return allSessions.filter { cal.isDate($0.date, inSameDayAs: Date()) && ($0.mode != "nursing") }
    }

    private var activeMom: MomProfile? {
        profiles.first { $0.id.uuidString == activeProfileStore.activeProfileID }
    }

    private var milkSessions: [MilkSession] {
        allMilkSessions.filter { $0.mom?.id == activeMom?.id }
    }

    // Lightweight snapshot we keep in UserDefaults so we do not change the data model
    private struct TimerSnap: Identifiable, Codable {
        let id: UUID
        let date: Date
        let seconds: Int
        let side: String // "left" | "right" | "both"
        let mode: String? // "pumping" | "nursing" (optional for backward compatibility)
    }
    private let snapsKeyPrefix = "MilkTimerSnaps-"

    // MARK: - Timer helpers
    private func loadSnaps() {
        let key = snapsKeyPrefix + Self.keyForToday()
        if let data = UserDefaults.standard.data(forKey: key),
           let out = try? JSONDecoder().decode([TimerSnap].self, from: data) {
            snaps = out
        } else {
            snaps = []
        }
    }
    private func saveSnaps() {
        let key = snapsKeyPrefix + Self.keyForToday()
        if let data = try? JSONEncoder().encode(snaps) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    private static func keyForToday() -> String {
        let d = Date()
        let c = Calendar.current.dateComponents([.year,.month,.day], from: d)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    private var elapsedString: String {
        let s = Int(elapsed.rounded())
        let m = s / 60, r = s % 60
        return String(format: "%02d:%02d", m, r)
    }
    private func startTimer() {
        guard !isTiming else { return }
        if currentSession == nil {
            let start = Date()
            timerStart = start
            let side: MilkSession.Side? = {
                switch selectedSide {
                case .left: return .left
                case .right: return .right
                default: return nil
                }
            }()
            let mode: MilkSession.Mode = selectedMode == "pumping" ? .pump : .nurse
            currentSession = MilkSession(mom: activeMom, mode: mode, side: side, start: start)
        } else {
            timerStart = Date()
        }
        isTiming = true
    }
    private func pauseTimer() {
        guard isTiming, let start = timerStart else { return }
        elapsed += Date().timeIntervalSince(start)
        isTiming = false
        timerStart = nil
    }
    private func stopTimer() {
        if isTiming, let start = timerStart { elapsed += Date().timeIntervalSince(start) }
        isTiming = false
        timerStart = nil

        let secs = Int(max(0, elapsed.rounded()))
        guard secs > 0 else { currentSession = nil; return }

        // Timestamp used for both the snapshot and an optional pump record
        let when = Date()

        // Persist snapshot (UI-only, includes mode)
        let snap = TimerSnap(
            id: UUID(),
            date: when,
            seconds: secs,
            side: selectedSide.rawValue,
            mode: selectedMode
        )
        snaps.append(snap)
        saveSnaps()

        // Create PumpSession with duration and mode
        var session = PumpSession(date: when, volumeOz: 0, durationSec: secs, mode: selectedMode)
        session.side = selectedSide
        context.insert(session)
        try? context.save()

        if selectedMode == "pumping" {
            pendingSession = session
            ozInput = ""
            showOzSheet = true
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            ActivityTracker.mark(.milk, in: context)
        }

        if var milk = currentSession {
            milk.end = when
            if milk.mom == nil { milk.mom = activeMom }
            if milk.modelContext == nil { context.insert(milk) }
            try? context.save()
        }
        currentSession = nil

        // Reset timer UI regardless
        elapsed = 0
        showConfetti = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { showConfetti = false }
    }

    private func finalizePumping() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        ActivityTracker.mark(.milk, in: context)
        pendingSession = nil
        ozInput = ""
        showOzSheet = false
    }

    private func commitPumpedOz() {
        guard let session = pendingSession else {
            showOzSheet = false
            return
        }
        if let oz = Double(ozInput), oz >= 0 {
            session.volumeOz = oz
            try? context.save()
        }
        finalizePumping()
    }

    private func skipPumpedOz() {
        finalizePumping()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    stopwatchCard
                    quickLogCard
                    sessionHistoryCard
                    todayCard
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .onAppear { loadSnaps() }
            .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
                if isTiming, let start = timerStart {
                    elapsed += Date().timeIntervalSince(start)
                    timerStart = Date() // step to prevent drift
                }
            }
            .withConfetti($showConfetti)
            .navigationTitle("Milk")
            .navigationBarTitleDisplayMode(.large)
            .background(LF.bg.ignoresSafeArea())
            .sheet(isPresented: $showOzSheet) {
                NavigationStack {
                    Form {
                        Section {
                            TextField("Ounces", text: $ozInput)
                                .keyboardType(.decimalPad)
                                .keyboardDoneToolbar()
                        }
                    }
                    .navigationTitle("Log ounces pumped?")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Skip") { skipPumpedOz() }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") { commitPumpedOz() }
                                .disabled(Double(ozInput) == nil)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var stopwatchCard: some View {
        Card {
            CardHeader(title: "Nursing / Pump Timer")

            Picker("Mode", selection: $selectedMode) {
                Text("Nursing").tag("nursing")
                Text("Pumping").tag("pumping")
            }
            .pickerStyle(.segmented)

            Picker("Side", selection: $selectedSide) {
                ForEach(BreastSide.allCases, id: \.self) { s in
                    switch s {
                    case .left:  Text("Left").tag(s)
                    case .right: Text("Right").tag(s)
                    case .both:  Text("Both").tag(s)
                    }
                }
            }
            .pickerStyle(.segmented)

            HStack(alignment: .lastTextBaseline, spacing: 12) {
                Text(elapsedString)
                    .font(.system(size: 40, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .frame(minWidth: 110, alignment: .leading)

                Spacer()

                Group {
                    if !isTiming && elapsed == 0 {
                        Button { startTimer() } label: {
                            label("Start", "play.fill")
                        }
                        .buttonStyle(.borderedProminent)
                    } else if isTiming {
                        HStack(spacing: 8) {
                            Button { pauseTimer() } label: {
                                label("Pause", "pause.fill")
                            }
                            Button { stopTimer() } label: {
                                label("Stop", "stop.fill")
                            }
                        }
                    } else {
                        HStack(spacing: 8) {
                            Button { startTimer() } label: {
                                label("Resume", "play.fill")
                            }
                            Button { stopTimer() } label: {
                                label("Stop", "stop.fill")
                            }
                        }
                    }
                }
                .controlSize(.regular)
            }
            .padding(.top, 6)
        }
    }

    @ViewBuilder
    private var quickLogCard: some View {
        Card {
            CardHeader(title: "Log pumping quickly")

            Picker("Side", selection: $selectedSide) {
                ForEach(BreastSide.allCases, id: \.self) { s in
                    switch s {
                    case .left:  Text("Left").tag(s)
                    case .right: Text("Right").tag(s)
                    case .both:  Text("Both").tag(s)
                    }
                }
            }
            .pickerStyle(.segmented)

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                TextField("Oz", text: $volume)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(minWidth: 70, maxWidth: 110)
                    .keyboardDoneToolbar()
                    .onSubmit { logPump() }

                Button { logPump() } label: { label("Add", "plus") }
                    .buttonStyle(.borderedProminent)

                Button { undoLast() } label: { label("Undo", "arrow.uturn.left") }
                    .buttonStyle(.bordered)
                    .tint(.gray)
            }
            .controlSize(.regular)
        }
    }

    @ViewBuilder
    private var sessionHistoryCard: some View {
        Card {
            CardHeader(title: "Recent Sessions")
            if milkSessions.isEmpty {
                Text("No sessions yet.")
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(milkSessions.prefix(10).enumerated()), id: \.element.id) { idx, s in
                        HStack {
                            Text(s.type.capitalized)
                            Spacer()
                            Text("\(timeOnly(s.startedAt)) - \(timeOnly(s.endedAt ?? s.startedAt))")
                                .foregroundStyle(.secondary)
                            Text(durationString(from: s.duration))
                                .monospacedDigit()
                                .frame(minWidth: 60, alignment: .trailing)
                        }
                        .padding(.vertical, 8)
                        if idx < min(10, milkSessions.count) - 1 { Divider().opacity(0.15) }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var todayCard: some View {
        Card {
            CardHeader(title: "Today")

            if todaySessions.isEmpty {
                Text("No sessions yet.")
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(todaySessions.enumerated()), id: \.element.id) { idx, s in
                        HStack {
                            HStack(spacing: 8) {
                                switch s.side {
                                case .left:  Image(systemName: "l.circle.fill").foregroundStyle(.blue)
                                case .right: Image(systemName: "r.circle.fill").foregroundStyle(.pink)
                                case .both:  Image(systemName: "circlebadge.2.fill").foregroundStyle(.secondary)
                                }
                                Text("\(Int(s.volumeOz)) oz").monospacedDigit()
                            }
                            Spacer()
                            Text(timeOnly(s.date)).foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 6)

                        if idx < todaySessions.count - 1 {
                            Divider().opacity(0.15)
                        }
                    }
                }

                let leftOz = todaySessions.filter { $0.side == .left }.map(\.volumeOz).reduce(0, +)
                let rightOz = todaySessions.filter { $0.side == .right }.map(\.volumeOz).reduce(0, +)
                let bothOz = todaySessions.filter { $0.side == .both }.map(\.volumeOz).reduce(0, +)
                let total = leftOz + rightOz + bothOz

                HStack(spacing: 14) {
                    Label("\(Int(total)) oz total", systemImage: "drop.fill")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Label("L \(Int(leftOz))", systemImage: "l.circle.fill")
                        .foregroundStyle(.blue)
                    Label("R \(Int(rightOz))", systemImage: "r.circle.fill")
                        .foregroundStyle(.pink)
                }
                .font(.footnote)
                .padding(.top, 8)

                if !snaps.isEmpty {
                    Divider().opacity(0.15).padding(.top, 8)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Timers today").font(.footnote).foregroundStyle(.secondary)
                        ForEach(snaps) { s in
                            HStack {
                                Image(systemName: "stopwatch.fill")
                                    .foregroundStyle(.orange)
                                if let kind = s.mode {
                                    Text(kind == "pumping" ? "Pump" : "Nurse")
                                        .font(.caption2).padding(.horizontal, 6).padding(.vertical, 2)
                                        .background(.thinMaterial, in: Capsule())
                                }
                                Text(durationString(from: s.seconds, side: s.side))
                                Spacer()
                                Text(timeOnly(s.date)).foregroundStyle(.secondary)
                            }
                            .font(.callout)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func logPump() {
        let oz = Double(volume) ?? 0
        var rec = PumpSession(date: Date(), volumeOz: oz, mode: "pumping")
        rec.side = selectedSide
        context.insert(rec)
        try? context.save()

        UINotificationFeedbackGenerator().notificationOccurred(.success)
        ActivityTracker.mark(.milk, in: context)

        volume = ""
        showConfetti = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { showConfetti = false }
    }

    private func undoLast() {
        if let last = todaySessions.first {
            context.delete(last)
            try? context.save()
        }
    }

    // MARK: - Helpers

    private func label(_ title: String, _ system: String) -> some View {
        Label(title, systemImage: system).labelStyle(.titleAndIcon)
    }

    private func durationString(from seconds: Int, side: String) -> String {
        let m = seconds / 60, s = seconds % 60
        let mark: String = {
            switch side {
            case "left": return "(Left)"
            case "right": return "(Right)"
            case "both": return "(Both)"
            default: return ""
            }
        }()
        return String(format: "%02d:%02d %@", m, s, mark)
    }

    private func durationString(from interval: TimeInterval) -> String {
        let s = Int(interval.rounded())
        let m = s / 60, r = s % 60
        return String(format: "%02d:%02d", m, r)
    }

    private func timeOnly(_ d: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: d)
    }

}
