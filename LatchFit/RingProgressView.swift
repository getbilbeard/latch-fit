import SwiftUI

public struct RingProgressView: View {
    public var progress: CGFloat           // 0…1

    public init(progress: CGFloat) {
        self.progress = progress
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(Color.lfSageLight, lineWidth: 10)

            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(Color.lfSageDeep, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: progress)
        }
        .opacity(Double(progress.isFinite ? 1 : 0)) // removes ambiguity
    }
}

public struct RingCenterLabel: View {
    public var title: String
    public var valueText: String
    public var subtitle: String

    public init(title: String, valueText: String, subtitle: String) {
        self.title = title
        self.valueText = valueText
        self.subtitle = subtitle
    }

    public var body: some View {
        VStack(spacing: 2) {
            Text(valueText)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Color.lfInk)
            Text(title)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Color.lfMutedText)
            Text(subtitle)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Color.lfMutedText)
        }
    }
}
