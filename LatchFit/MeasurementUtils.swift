import SwiftUI
import Foundation

// MARK: - Unit preference (saved per device)
public enum UnitPreference: String, CaseIterable, Identifiable {
    case imperial   // ft/in + lb
    case metric     // cm + kg
    public var id: String { rawValue }
    public var title: String { self == .imperial ? "Imperial (ft/in, lb)" : "Metric (cm, kg)" }
}

/// App-wide unit preference using AppStorage (per device, per Apple ID)
public struct UnitSettings {
    @AppStorage("unitPreference") public static var preference: UnitPreference = .imperial
}

// MARK: - Conversions
@inlinable public func ftInToCm(ft: Int, inch: Int) -> Double {
    let totalInches = (ft * 12) + inch
    return Double(totalInches) * 2.54
}

@inlinable public func cmToFtIn(_ cm: Double) -> (ft: Int, inch: Int) {
    let totalInches = cm / 2.54
    let ft = Int(totalInches / 12.0)
    let inch = max(0, Int((totalInches.rounded()) - Double(ft * 12)))
    return (ft, inch)
}

@inlinable public func lbToKg(_ lb: Double) -> Double { lb * 0.45359237 }
@inlinable public func kgToLb(_ kg: Double) -> Double { kg / 0.45359237 }

// MARK: - Formatting helpers
public func formatHeight(cm: Double, preference: UnitPreference = UnitSettings.preference) -> String {
    switch preference {
    case .imperial:
        let p = cmToFtIn(cm)
        return "\(p.ft)′\(p.inch)″"
    case .metric:
        return "\(Int(cm.rounded())) cm"
    }
}

public func formatWeight(lb: Double, preference: UnitPreference = UnitSettings.preference) -> String {
    switch preference {
    case .imperial:
        return "\(Int(lb.rounded())) lb"
    case .metric:
        let kg = lbToKg(lb)
        return "\(Int(kg.rounded())) kg"
    }
}

// MARK: - Keyboard toolbar
public struct KeyboardDoneToolbar: ViewModifier {
    @FocusState private var isFocused: Bool
    public func body(content: Content) -> some View {
        content
            .focused($isFocused)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { UIApplication.shared.endEditing() }
                }
            }
    }
}

public extension View {
    func keyboardDoneToolbar() -> some View { modifier(KeyboardDoneToolbar()) }
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

