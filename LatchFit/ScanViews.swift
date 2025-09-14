import SwiftUI

struct ScanLabelView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var text: String = ""
    var onParsedMacros: ((Int, Int, Int, Int) -> Void)? // calories, protein, fat, carbs

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Paste nutrition text or type a quick label to parse:")
                    .foregroundStyle(.secondary)
                TextEditor(text: $text)
                    .frame(minHeight: 180)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(SwiftUI.Color.secondary.opacity(0.2)))
                Button {
                    // Dummy parse — replace with Vision text detection
                    let cal = 120, protein = 12, fat = 4, carbs = 14
                    onParsedMacros?(cal, protein, fat, carbs)
                    dismiss()
                } label: {
                    Text("Parse").frame(maxWidth: .infinity)
                }.buttonStyle(.borderedProminent)
            }
              .padding()
              .navigationTitle("Scan Label")
          }
          .toolbar {
              ToolbarItem(placement: .cancellationAction) {
                  Button("Close") { dismiss() }
              }
          }
      }
  }

