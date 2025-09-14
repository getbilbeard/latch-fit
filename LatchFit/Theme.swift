import SwiftUI

extension LinearGradient {
    static var lfRing: LinearGradient {
        LinearGradient(
            colors: [Color.lfSageDeep, Color.lfSage, Color.lfSageLight],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

extension Font {
    static var cardTitle: Font { .system(.title3, design: .rounded).weight(.semibold) }
    static var ringBig:    Font { .system(size: 36, weight: .bold, design: .rounded) }
}
