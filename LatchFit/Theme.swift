import SwiftUI

extension Color {
    static let lfSage      = Color(hex: 0x8FAE9E)
    static let lfSageDeep  = Color(hex: 0x6E9075)
    static let lfSageLight = Color(hex: 0xC9DACF)
    static let lfLeaf      = Color(hex: 0x98C1A2)
    static let lfAmber     = Color(hex: 0xDFAF2B)
    static let lfInk       = Color(hex: 0x1E1F22)
    static let lfMutedText = Color(hex: 0x6B7280)
    static let lfCardBG    = Color(uiColor: .secondarySystemBackground)
    static let lfCanvasBG  = Color(uiColor: .systemBackground)
}

extension LinearGradient {
    static var lfRing: LinearGradient {
        LinearGradient(colors: [.lfSageDeep, .lfSage, .lfLeaf],
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
    static var smallLabel: Font { .system(.footnote, design: .rounded) }
}
