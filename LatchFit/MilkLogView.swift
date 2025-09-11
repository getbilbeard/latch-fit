import SwiftUI
import SwiftData

enum SessionKind: String, CaseIterable { case pumping, nursing }

struct MilkLogView: View {
    @Environment(\.modelContext) private var context

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

    @State private var selectedKind: SessionKind? = nil
    @State private var showOzSheet = false
    @State private var ozInput = ""
    @State private var pendingDate: Date? = nil

    // Today-only view (computed from allSessions)
    private var todaySessions: [PumpSession] {
        let cal = Calendar.current
        return allSessions.filter { cal.isDate($0.date, inSameDayAs: Date()) }
    }

    // Lightweight snapshot we keep in UserDefaults so we do not change the data model
    private struct TimerSnap: Identifiable, Codable {
        let id: UUID
        let date: Date
        let seconds: Int
        let side: String // "left" | "right" | "both"
        let kind: String? // "pumping" | "nursing" (optional for backward compatibility)
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
    private func startTimer() { guard !isTiming else { return }; isTiming = true; timerStart = Date() }
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
        guard secs > 0 else { return }

        // Timestamp used for both the snapshot and an optional pump record
        let when = Date()

        // Persist snapshot (UI-only, includes kind)
        let snap = TimerSnap(
            id: UUID(),
            date: when,
            seconds: secs,
            side: selectedSide.rawValue,
            kind: selectedKind?.rawValue
        )
        snaps.append(snap)
        saveSnaps()

        // If the user is pumping, ask for ounces; otherwise we're done (nursing time only)
        if selectedKind == .pumping {
            pendingDate = when
            ozInput = ""
            showOzSheet = true
        } else {
            // Haptics + streak for nursing-only time log
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            ActivityTracker.mark(.milk, in: context)
        }

        // Reset timer UI regardless
        elapsed = 0
        showConfetti = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { showConfetti = false }
    }

    private func commitPumpedOz() {
        guard let when = pendingDate, let oz = Double(ozInput), oz >= 0 else {
            showOzSheet = false
            return
        }
        var rec = PumpSession(date: when, volumeOz: oz)
        rec.side = selectedSide
        context.insert(rec)
        try? context.save()

        UINotificationFeedbackGenerator().notificationOccurred(.success)
        ActivityTracker.mark(.milk, in: context)

        pendingDate = nil
        ozInput = ""
        showOzSheet = false
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    stopwatchCard
                    quickLogCard
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
                        Section("Log pumped milk") {
                            TextField("Ounces", text: $ozInput)
                                .keyboardType(.decimalPad)
                                .keyboardDoneToolbar()
                        }
                    }
                    .navigationTitle("Pumped amount")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showOzSheet = false; pendingDate = nil }
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

            HStack(spacing: 8) {
                modeSegment("Pumping", .pumping)
                modeSegment("Nursing", .nursing)
                Spacer()
            }

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

                let canTime = (selectedKind != nil)
                Group {
                    if !isTiming && elapsed == 0 {
                        Button { startTimer() } label: {
                            label("Start", "play.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!canTime)
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
                                if let kind = s.kind {
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
        var rec = PumpSession(date: Date(), volumeOz: oz)
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

    private func timeOnly(_ d: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: d)
    }

    private func modeSegment(_ title: String, _ kind: SessionKind) -> some View {
        Button {
            selectedKind = kind
        } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .buttonStyle(.bordered)
        .tint(selectedKind == kind ? .accentColor : .gray.opacity(0.4))
        .clipShape(Capsule())
    }
}
