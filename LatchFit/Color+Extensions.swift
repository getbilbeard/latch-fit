import SwiftUI

extension Color {
    // Sage palette
    static let lfSageLight = Color("lfSageLight")
    static let lfSage      = Color("lfSage")
    static let lfSageDark  = Color("lfSageDark")
    static let lfSageDeep  = Color("lfSageDeep")

    // Accent
    static let lfAmber = Color("lfAmber")

    // Backgrounds
    static let lfCanvasBG = Color("lfCanvasBG")
    static let lfCardBG   = Color("lfCardBG")

    // Text
    static let lfTextPrimary   = Color("lfTextPrimary")
    static let lfTextSecondary = Color("lfTextSecondary")
    static let lfMutedText     = Color.black.opacity(0.4) // fallback
    static let lfInk           = Color.primary             // fallback
}
