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
    @State private var showNoProfileAlert = false
    @State private var toastText: String? = nil

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

            Text(formatElapsed(Int(elapsed)))
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

    // MARK: - Actions
    private func startLeft() {
        if leftRunning {
            stopLeft()
            return
        }
        guard activeMom != nil else { showNoProfileAlert = true; return }
        leftStart = Date()
        leftRunning = true
    }
    private func startRight() {
        if rightRunning {
            stopRight()
            return
        }
        guard activeMom != nil else { showNoProfileAlert = true; return }
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
        guard let mom = activeMom else { showNoProfileAlert = true; return }
        guard end > start else { return }
        let session = MilkSession(mom: mom,
                                  mode: selectedMode,
                                  side: side,
                                  start: start,
                                  end: end)
        context.insert(session)
        try? context.save()
        let mins = session.durationSec / 60
        showToast("Logged \(side == .left ? "Left" : "Right") • \(selectedMode == .nurse ? "Nurse" : "Pump") • \(mins)m")
    }

    private func showToast(_ text: String) {
        withAnimation { toastText = text }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { toastText = nil }
        }
        bump()
    }
}

// Minimal preview for SwiftUI canvas
#Preview {
    MilkTimerPanels()
        .environmentObject(ActiveProfileStore())
}
