import SwiftUI
import SwiftData
import Foundation

/// Compact summary row for the day's pumping activity.
/// - Shows Sessions, Total Volume (oz), Avg / Session, and Minutes (est.)
/// - Minutes currently uses a conservative estimate (10 min / session).
///   When you add a `durationSeconds` field to `PumpSession`, swap the
///   `estimatedMinutes` computation with the commented real-minutes block.
struct PumpHistorySummary: View {
    let sessions: [PumpSession]

    // MARK: - Derived metrics

    private var totalOz: Double {
        sessions.map(\.volumeOz).reduce(0, +)
    }

    private var sessionsCount: Int {
        sessions.count
    }

    private var avgPerSession: Double {
        guard sessionsCount > 0 else { return 0 }
        return totalOz / Double(sessionsCount)
    }

    /// Estimated minutes until we persist real durations on `PumpSession`.
    private var estimatedMinutes: Int {
        // Replace this when `durationSeconds` exists on PumpSession:
        // let seconds = sessions.map(\.durationSeconds).reduce(0, +)
        // return max(1, seconds / 60)
        max(0, sessionsCount * 10)
    }

    // MARK: - View

    var body: some View {
        HStack(spacing: 12) {
            SummaryChip(icon: "number.circle.fill",
                        tint: .blue,
                        title: "Sessions",
                        value: "\(sessionsCount)")

            SummaryChip(icon: "drop.fill",
                        tint: .teal,
                        title: "Total (oz)",
                        value: totalOz.formatted(.number.precision(.fractionLength(0...1))))

            SummaryChip(icon: "gauge.with.dots.needle.bottom.0percent",
                        tint: .indigo,
                        title: "Avg / Session",
                        value: avgPerSession.formatted(.number.precision(.fractionLength(0...1))))

            SummaryChip(icon: "timer",
                        tint: .orange,
                        title: "Minutes",
                        value: "\(estimatedMinutes)")
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Pump summary. \(sessionsCount) sessions, \(Int(totalOz.rounded())) ounces total, average \(avgPerSession.formatted(.number.precision(.fractionLength(0...1)))) ounces per session, \(estimatedMinutes) minutes.")
    }
}

private struct SummaryChip: View {
    let icon: String
    let tint: Color
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(tint)

            Text(value)
                .font(.headline)
                .monospacedDigit()

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.thinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(.black.opacity(0.06))
        )
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

