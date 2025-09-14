import SwiftUI
import JBDatePicker

struct JBDatePickerWrapper: UIViewRepresentable {
    func makeUIView(context: Context) -> JBDatePickerView {
        return JBDatePickerView()
    }

    func updateUIView(_ uiView: JBDatePickerView, context: Context) {}
}

