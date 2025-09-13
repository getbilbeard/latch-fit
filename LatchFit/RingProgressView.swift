import SwiftUI

struct RingProgressView: View {
    var progress: CGFloat
    var lineWidth: CGFloat = 14
    var showShadow = true

    var body: some View {
        ZStack {
            Circle().stroke(Color.lfSageLight.opacity(0.35), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0, min(progress, 1)))
                .stroke(LinearGradient.lfRing, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: showShadow ? .black.opacity(0.1) : .clear, radius: 4, y: 2)
                .animation(.spring(duration: 0.7, bounce: 0.25), value: progress)
        }
    }
}

struct RingCenterLabel: View {
    let title: String
    let valueText: String
    let subtitle: String?

    var body: some View {
        VStack(spacing: 4) {
            Text(valueText).font(.ringBig).foregroundStyle(Color.lfTextPrimary)
            Text(title).font(.footnote).foregroundStyle(Color.lfTextSecondary)
            if let subtitle { Text(subtitle).font(.smallLabel).foregroundStyle(Color.lfTextSecondary) }
        }
    }
}
