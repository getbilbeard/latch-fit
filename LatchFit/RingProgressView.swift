import SwiftUI

struct RingProgressView: View {
    var progress: CGFloat        // 0...1
    var lineWidth: CGFloat = 12

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.lfSageLight.opacity(0.3), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [Color.lfSageDark, Color.lfSageDeep, Color.lfSage]),
                        center: .center),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .accessibilityLabel("Progress")
        .accessibilityValue(Text("\(Int(progress * 100)) percent"))
    }
}

struct RingCenterLabel: View {
    var title: String
    var valueText: String
    var subtitle: String?

    var body: some View {
        VStack(spacing: 4) {
            Text(valueText)
                .font(.largeTitle.weight(.semibold))
                .foregroundStyle(Color.lfTextPrimary)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            if let subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
