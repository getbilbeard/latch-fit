import SwiftUI

extension LinearGradient {
    static var lfRing: LinearGradient {
        LinearGradient(colors: [.lfSageDeep, .lfSage, .lfSageLight],
                       startPoint: .topLeading,
                       endPoint: .bottomTrailing)
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

extension Font {
    static var cardTitle: Font { .system(.title3, design: .rounded).weight(.semibold) }
    static var ringBig:    Font { .system(size: 36, weight: .bold, design: .rounded) }
}
