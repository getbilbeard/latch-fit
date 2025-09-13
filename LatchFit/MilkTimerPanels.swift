import SwiftUI
import SwiftData

/// Timer UI for left and right sides. Each side can run independently and
/// logs a `MilkSession` when stopped.
struct MilkTimerPanels: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var activeProfileStore: ActiveProfileStore
    @Query(sort: [SortDescriptor(\MomProfile.createdAt, order: .reverse)])
    private var profiles: [MomProfile]

    /// Persist the last selected mode between launches.
    @AppStorage("MilkTimerMode") private var modeRaw: String = MilkSession.Mode.nurse.rawValue
    private var modeBinding: Binding<MilkSession.Mode> {
        Binding<MilkSession.Mode>(
            get: { MilkSession.Mode(rawValue: modeRaw) ?? .nurse },
            set: { modeRaw = $0.rawValue }
        )
    }
    private var selectedMode: MilkSession.Mode {
        MilkSession.Mode(rawValue: modeRaw) ?? .nurse
    }

    // Independent timer state for each side
    @State private var leftRunning = false
    @State private var rightRunning = false
    @State private var leftStart: Date? = nil
    @State private var rightStart: Date? = nil
    @State private var now: Date = Date()

    private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var activeMom: MomProfile? {
        profiles.first { $0.id.uuidString == activeProfileStore.activeProfileID }
    }

    var body: some View {
        VStack(spacing: 16) {
            Picker("Mode", selection: modeBinding) {
                Text("Nurse").tag(MilkSession.Mode.nurse)
                Text("Pump").tag(MilkSession.Mode.pump)
            }
            .pickerStyle(.segmented)

            HStack(spacing: 16) {
                sidePanel(side: .left,
                          running: $leftRunning,
                          start: $leftStart,
                          elapsed: leftElapsed,
                          startAction: startLeft,
                          stopAction: stopLeft)
                sidePanel(side: .right,
                          running: $rightRunning,
                          start: $rightStart,
                          elapsed: rightElapsed,
                          startAction: startRight,
                          stopAction: stopRight)
            }
        }
        .onReceive(timer) { date in
            now = date
        }
    }

    // MARK: - Panels
    @ViewBuilder
    private func sidePanel(side: MilkSession.Side,
                           running: Binding<Bool>,
                           start: Binding<Date?>,
                           elapsed: TimeInterval,
                           startAction: @escaping () -> Void,
                           stopAction: @escaping () -> Void) -> some View {
        VStack(spacing: 12) {
            Text(side == .left ? "Left" : "Right")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(timeString(from: elapsed))
                .font(.system(size: 40, weight: .semibold, design: .rounded))
                .monospacedDigit()

            Button {
                running.wrappedValue ? stopAction() : startAction()
            } label: {
                Label(running.wrappedValue ? "Stop" : "Start",
                      systemImage: running.wrappedValue ? "stop.fill" : "play.fill")
                    .frame(minWidth: 80)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }

    // MARK: - Elapsed helpers
    private var leftElapsed: TimeInterval {
        guard leftRunning, let start = leftStart else { return 0 }
        return now.timeIntervalSince(start)
    }

    private var rightElapsed: TimeInterval {
        guard rightRunning, let start = rightStart else { return 0 }
        return now.timeIntervalSince(start)
    }

    private func timeString(from interval: TimeInterval) -> String {
        let secs = Int(interval.rounded())
        let m = secs / 60
        let s = secs % 60
        return String(format: "%02d:%02d", m, s)
    }

    // MARK: - Actions
    private func startLeft() {
        guard !leftRunning else { return }
        leftStart = Date()
        leftRunning = true
    }
    private func startRight() {
        guard !rightRunning else { return }
        rightStart = Date()
        rightRunning = true
    }

    private func stopLeft() {
        guard leftRunning, let start = leftStart else { return }
        let end = Date()
        logSession(side: .left, start: start, end: end)
        leftRunning = false
        leftStart = nil
    }
    private func stopRight() {
        guard rightRunning, let start = rightStart else { return }
        let end = Date()
        logSession(side: .right, start: start, end: end)
        rightRunning = false
        rightStart = nil
    }

    private func logSession(side: MilkSession.Side, start: Date, end: Date) {
        var session = MilkSession(mom: activeMom,
                                  mode: selectedMode,
                                  side: side,
                                  start: start,
                                  end: end)
        context.insert(session)
        try? context.save()
    }
}

// Minimal preview for SwiftUI canvas
#Preview {
    MilkTimerPanels()
        .environmentObject(ActiveProfileStore())
}
