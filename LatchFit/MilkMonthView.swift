import SwiftUI
import SwiftData

/// Monthly calendar for milk sessions.
struct MilkMonthView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var activeProfileStore: ActiveProfileStore
    @Query(sort: [SortDescriptor(\MomProfile.createdAt, order: .reverse)])
    private var profiles: [MomProfile]
    @Query(sort: [SortDescriptor(\MilkSession.startedAt, order: .reverse)])
    private var allSessions: [MilkSession]
    @State private var monthOffset = 0

    private var cal: Calendar { Calendar.current }

    private var monthStart: Date {
        let base = cal.date(byAdding: .month, value: monthOffset, to: Date()) ?? Date()
        let comps = cal.dateComponents([.year, .month], from: base)
        return cal.date(from: comps) ?? Date()
    }
    private var monthEnd: Date {
        cal.date(byAdding: .month, value: 1, to: monthStart) ?? monthStart
    }

    private var activeMom: MomProfile? {
        profiles.first { $0.id.uuidString == activeProfileStore.activeProfileID }
    }

    private var sessions: [MilkSession] {
        allSessions.filter { $0.mom?.id == activeMom?.id }
    }
    private var monthSessions: [MilkSession] {
        sessions.filter { $0.start >= monthStart && $0.start < monthEnd }
    }
    private var groupedByDay: [Date: [MilkSession]] {
        Dictionary(grouping: monthSessions) { cal.startOfDay(for: $0.start) }
    }

    private var daysInMonth: [Date] {
        let range = cal.range(of: .day, in: .month, for: monthStart) ?? 1..<31
        return range.compactMap { day -> Date? in
            var comps = cal.dateComponents([.year, .month], from: monthStart)
            comps.day = day
            return cal.date(from: comps)
        }
    }
    private var leadingBlankCount: Int {
        let first = daysInMonth.first ?? monthStart
        let wk = cal.component(.weekday, from: first)
        return wk - 1
    }

    private var highScoreDay: Date? {
        groupedByDay.max { $0.value.count < $1.value.count }?.key
    }
    private var lowScoreDay: Date? {
        let nonZero = groupedByDay.filter { !$0.value.isEmpty }
        return nonZero.min { $0.value.count < $1.value.count }?.key
    }

    private func counts(for day: Date) -> (total: Int, minutes: Int) {
        let arr = groupedByDay[day] ?? []
        let mins = arr.map(\.durationSec).reduce(0, +) / 60
        return (arr.count, mins)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    header
                    calendar
                    highScoreCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } } }
            .background(LF.bg.ignoresSafeArea())
        }
    }

    private var header: some View {
        HStack {
            Button { monthOffset -= 1 } label: {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Text(monthTitle(monthStart))
                .font(.headline)
            Spacer()
            Button { monthOffset += 1 } label: {
                Image(systemName: "chevron.right")
            }
        }
    }

    private var calendar: some View {
        VStack(spacing: 8) {
            HStack {
                ForEach(cal.shortWeekdaySymbols, id: \.self) { s in
                    Text(s.uppercased())
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 8) {
                ForEach(0..<leadingBlankCount, id: \.self) { _ in Color.clear.frame(height: 40) }
                ForEach(daysInMonth, id: \.self) { day in
                    let c = counts(for: day)
                    VStack(spacing: 2) {
                        Text("\(cal.component(.day, from: day))")
                            .font(.caption)
                        Text("\(c.total)")
                            .font(.caption2)
                        if c.minutes > 0 {
                            Text("\(c.minutes)m")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .padding(4)
                    .background(
                        RoundedRectangle(cornerRadius: 8).stroke(LF.stroke, lineWidth: 1)
                    )
                }
            }
        }
    }

    private var highScoreCard: some View {
        Card {
            CardHeader(title: "High/Low")
            VStack(alignment: .leading, spacing: 4) {
                if let high = highScoreDay {
                    let c = counts(for: high)
                    Text("Most sessions: \(dayString(high)) (\(c.total))")
                }
                if let low = lowScoreDay {
                    let c = counts(for: low)
                    Text("Least sessions: \(dayString(low)) (\(c.total))")
                }
            }
            .font(.subheadline)
        }
    }

    private func dayString(_ d: Date) -> String {
        let f = DateFormatter(); f.dateStyle = .medium; return f.string(from: d)
    }
    private func monthTitle(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "LLLL yyyy"; return f.string(from: d)
    }
}

#Preview {
    MilkMonthView().environmentObject(ActiveProfileStore())
}

