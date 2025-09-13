import SwiftUI

// Centralized app palette. These map to Color Assets in the asset catalog.
extension Color {
    // Sage Green Palette
    static var lfSageLight: Color { Color("lfSageLight") }
    static var lfSage:      Color { Color("lfSage") }
    static var lfSageDark:  Color { Color("lfSageDark") }
    static var lfSageDeep:  Color { Color("lfSageDeep") }

    // Accent / Highlight
    static var lfAmber:     Color { Color("lfAmber") }

    // Neutral Backgrounds
    static var lfCanvasBG:  Color { Color("lfCanvasBG") }
    static var lfCardBG:    Color { Color("lfCardBG") }

    // Text Colors
    static var lfTextPrimary:   Color { Color("lfTextPrimary") }
    static var lfTextSecondary: Color { Color("lfTextSecondary") }
}
