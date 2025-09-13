import SwiftUI

// Centralized app palette (Sage theme)
public extension Color {
    // Sage family
    static let lfSageLight = Color("lfSageLight")
    static let lfSage      = Color("lfSage")
    static let lfSageDark  = Color("lfSageDark")
    static let lfSageDeep  = Color("lfSageDeep")

    // Accent
    static let lfAmber     = Color("lfAmber")

    // Backgrounds
    static let lfCanvasBG  = Color("lfCanvasBG")
    static let lfCardBG    = Color("lfCardBG")

    // Text system
    static let lfTextPrimary   = Color("lfTextPrimary")
    static let lfTextSecondary = Color("lfTextSecondary")

    // Convenience text colors that must remain true Color (NOT views)
    static let lfInk        = Color(.label)
    static let lfMutedText  = Color(.secondaryLabel)
}
