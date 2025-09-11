import SwiftUI

// MARK: - Theme
enum LF {
    static let bg = Color(.systemGroupedBackground)
    static let cardBG = Color(.secondarySystemBackground)
    static let stroke = Color.black.opacity(0.06)
    static let corner: CGFloat = 14
    static let pad: CGFloat = 16
    // Accent palette used across the app
    static let accent = Color.accentColor
    static let accentSoft = Color.accentColor.opacity(0.12)
}

// MARK: - Card + Header
struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) { content }
            .padding(14)
            .background(LF.cardBG, in: RoundedRectangle(cornerRadius: LF.corner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: LF.corner, style: .continuous)
                    .stroke(LF.stroke, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    }
}

struct CardHeader: View {
    let title: String
    var subtitle: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.caption)
                .foregroundStyle(.secondary)
            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Inputs
struct LabeledField<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder var content: Content
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: systemImage).foregroundStyle(.blue)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline)
                content
            }
        }
    }
}

// MARK: - Buttons
/// Primary capsule button that **never clips text** and adapts to Dynamic Type.
struct CapsuleButton: View {
    var title: String
    var systemName: String
    var role: ButtonRole? = nil
    var action: () -> Void
    var body: some View {
        Button(role: role, action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemName)
                Text(title)
                    .font(.callout.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .allowsTightening(true)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .frame(minHeight: 44)
            .contentShape(Capsule())
        }
        .buttonStyle(.borderedProminent)
        .tint(LF.accent)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        .fixedSize(horizontal: false, vertical: true)
    }
}


// MARK: - Small bits
struct Toast: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(LF.stroke))
    }
}

/// Simple haptic utility
func bump(_ style: UINotificationFeedbackGenerator.FeedbackType = .success) {
    let h = UINotificationFeedbackGenerator()
    h.notificationOccurred(style)
}
