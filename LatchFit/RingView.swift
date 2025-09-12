import SwiftUI

/// Simple circular progress ring (0…1)
struct Ring: Shape {
    var progress: CGFloat

    // allow implicit animations
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let radius = min(rect.width, rect.height) / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let startAngle = Angle(degrees: -90)
        let endAngle = Angle(degrees: -90 + 360 * progress)

        var p = Path()
        p.addArc(center: center,
                 radius: radius,
                 startAngle: startAngle,
                 endAngle: endAngle,
                 clockwise: false)
        return p.strokedPath(.init(lineWidth: 10, lineCap: .round))
    }
}

struct RingView: View {
    var progress: CGFloat        // 0...1
    var tint: Color = .teal

    var body: some View {
        ZStack {
            Circle()
                .stroke(.quaternary, lineWidth: 10)
            Ring(progress: max(0, min(progress, 1)))
                .fill(tint)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Progress"))
        .accessibilityValue(Text("\(Int(progress * 100)) percent"))
        .animation(.easeInOut(duration: 0.35), value: progress)
    }
}

#if DEBUG
struct RingView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 24) {
            RingView(progress: 0.25)
                .frame(width: 120, height: 120)
            RingView(progress: 0.8, tint: .pink)
                .frame(width: 120, height: 120)
        }
        .padding()
    }
}
#endif

