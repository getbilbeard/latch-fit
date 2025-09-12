import SwiftUI
import SwiftData

struct BreastTimerPanel: View {
    enum Side { case left, right }
    let side: Side
    let title: String
    @Binding var isTiming: Bool
    @Binding var elapsed: TimeInterval
    let onStart: () -> Void
    let onPause: () -> Void
    let onStop: () -> Void

    private var progress: CGFloat {
        // visual only: show up to 20 minutes as one full ring
        let cap: TimeInterval = 20*60
        return CGFloat(min(elapsed / cap, 1.0))
    }
    private var big: String {
        let s = Int(elapsed.rounded())
        let m = s / 60, r = s % 60
        return String(format: "%02d:%02d", m, r)
    }

    var body: some View {
        VStack(spacing: 14) {
            Text(title).font(.subheadline).foregroundStyle(.secondary)

            ZStack {
                RingView(progress: progress, tint: side == .left ? .blue : .pink)
                    .frame(width: 108, height: 108)
                Text(big).font(.system(size: 22, weight: .semibold, design: .rounded))
                    .monospacedDigit()
            }

            HStack(spacing: 10) {
                if isTiming {
                    Button {
                        onPause()
                    } label: { Label("Pause", systemImage: "pause.fill") }
                        .buttonStyle(.bordered)
                    Button {
                        onStop()
                    } label: { Label("Stop", systemImage: "stop.fill") }
                        .buttonStyle(.borderedProminent)
                } else {
                    Button {
                        onStart()
                    } label: { Label("Start", systemImage: "play.fill") }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

