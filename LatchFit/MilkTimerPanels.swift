import SwiftUI

/// Stateless timer panels for left and right sides.
/// Drives actions in the parent `MilkLogView` via callbacks.
struct MilkTimerPanels: View {
    @Binding var left: MilkLogView.TimerState
    @Binding var right: MilkLogView.TimerState
    @Binding var mode: MilkSession.Mode
    var start: (MilkSession.Side) -> Void
    var pause: (MilkSession.Side) -> Void
    var resume: (MilkSession.Side) -> Void
    var stop: (MilkSession.Side) -> Void

    @State private var now: Date = Date()
    private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(
        left: Binding<MilkLogView.TimerState>,
        right: Binding<MilkLogView.TimerState>,
        mode: Binding<MilkSession.Mode>,
        start: @escaping (MilkSession.Side) -> Void,
        pause: @escaping (MilkSession.Side) -> Void,
        resume: @escaping (MilkSession.Side) -> Void,
        stop: @escaping (MilkSession.Side) -> Void
    ) {
        _left = left
        _right = right
        _mode = mode
        self.start = start
        self.pause = pause
        self.resume = resume
        self.stop = stop
    }

    var body: some View {
        VStack(spacing: 16) {
            Picker("Mode", selection: $mode) {
                Text("Nurse").tag(MilkSession.Mode.nurse)
                Text("Pump").tag(MilkSession.Mode.pump)
            }
            .pickerStyle(.segmented)

            HStack(spacing: 16) {
                sidePanel(side: .left, session: $left)
                sidePanel(side: .right, session: $right)
            }
        }
        .onReceive(timer) { date in
            // tick only when a timer is running to refresh the elapsed labels
            if left.isRunning || right.isRunning {
                now = date
            }
        }
    }

    @ViewBuilder
    private func sidePanel(side: MilkSession.Side, session: Binding<MilkLogView.TimerState>) -> some View {
        VStack(spacing: 12) {
            Text(side == .left ? "Left" : "Right")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(formatElapsed(session.wrappedValue.durationSec))
                .font(.system(size: 40, weight: .semibold, design: .rounded))
                .monospacedDigit()

            if session.wrappedValue.isRunning {
                HStack(spacing: 8) {
                    Button("Pause") { pause(side) }
                        .buttonStyle(.borderedProminent)
                    Button("Stop") { stop(side) }
                        .buttonStyle(.bordered)
                }
            } else if session.wrappedValue.isPaused {
                HStack(spacing: 8) {
                    Button("Resume") { resume(side) }
                        .buttonStyle(.borderedProminent)
                    Button("Stop") { stop(side) }
                        .buttonStyle(.bordered)
                }
            } else {
                Button("Start") { start(side) }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
    }
}

#if DEBUG
#Preview {
    // Sample timer preview with default stopped state
    MilkTimerPanels(
        left: .constant(.preview),
        right: .constant(.preview),
        mode: .constant(.nurse),
        start: { _ in }, pause: { _ in }, resume: { _ in }, stop: { _ in }
    )
}
#endif

