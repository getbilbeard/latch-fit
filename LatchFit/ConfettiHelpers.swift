import SwiftUI

// Call: .withConfetti($showConfetti)
struct ConfettiModifier: ViewModifier {
    @Binding var isActive: Bool
    @StateObject private var controller = ConfettiController()

    func body(content: Content) -> some View {
        ZStack {
            content
            if isActive {
                ConfettiView()
                    .transition(.opacity)
                    .onAppear { controller.fireDebounced() }
                    .onChange(of: isActive) { _, newVal in
                        if newVal { controller.fireDebounced() }
                    }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isActive)
    }
}

extension View {
    func withConfetti(_ isActive: Binding<Bool>) -> some View {
        self.modifier(ConfettiModifier(isActive: isActive))
    }
}

// MARK: - Controller with debounce
final class ConfettiController: ObservableObject {
    private var lastFire: Date = .distantPast
    private let minGap: TimeInterval = 0.8

    func fireDebounced() {
        let now = Date()
        guard now.timeIntervalSince(lastFire) > minGap else { return }
        lastFire = now
        // if you have a 3rd-party confetti lib, trigger it here
        // otherwise the simple ConfettiView below fades itself
    }
}

struct ConfettiView: View {
    @State private var opacity = 1.0
    var body: some View {
        Rectangle()
            .fill(.clear)
            .background(
                TimelineView(.animation) { _ in
                    // placeholder sparkle burst
                    ZStack {
                        ForEach(0..<18, id: \.self) { i in
                            Circle()
                                .fill(.pink.opacity(0.8))
                                .frame(width: 6, height: 6)
                                .offset(x: CGFloat.random(in: -120...120),
                                        y: CGFloat.random(in: -60...60))
                                .opacity(Double.random(in: 0.7...1))
                        }
                    }
                }
            )
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) { opacity = 0 }
            }
            .opacity(opacity)
            .allowsHitTesting(false)
    }
}
