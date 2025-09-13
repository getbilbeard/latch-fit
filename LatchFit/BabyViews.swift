import SwiftUI
import SwiftData

// MARK: - BabyView
struct BabyView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var activeProfileStore: ActiveProfileStore
    @Query(sort: [SortDescriptor(\MomProfile.createdAt, order: .reverse)]) private var profiles: [MomProfile]
    @Query(sort: [SortDescriptor(\DiaperEvent.time, order: .reverse)]) private var events: [DiaperEvent]

    @State private var showCalendar = false
    @State private var showResetConfirm = false

    // Falling icon state
    @State private var fallID: UUID? = nil
    @State private var fallKind: String = "wet"
    @State private var fallStart: CGFloat = -120
    @State private var fallEnd: CGFloat = 900
    @State private var fallX: CGFloat = 0
    @State private var containerHeight: CGFloat = 0

    private var activeMom: MomProfile? {
        profiles.first { $0.id.uuidString == activeProfileStore.activeProfileID }
    }

    private var eventsForMom: [DiaperEvent] {
        events.filter { $0.mom?.id == activeMom?.id }
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ZStack(alignment: .top) {
                    ScrollView {
                        VStack(spacing: 16) {
                            quickAddCard
                            todayCard
                            recentCard
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 24)
                    }
                    if fallID != nil {
                        FallingIcon(kind: fallKind, x: fallX, startY: fallStart, endY: fallEnd)
                            .allowsHitTesting(false)
                            .transition(.opacity)
                    }
                }
                .onAppear { containerHeight = geo.size.height }
                .onChange(of: geo.size.height) { _, newVal in containerHeight = newVal }
            }
            .navigationTitle("Baby")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(role: .destructive) { showResetConfirm = true } label: {
                        Label("Reset Day", systemImage: "trash")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showCalendar = true } label: {
                        Label("Calendar", systemImage: "calendar")
                    }
                }
            }
            .sheet(isPresented: $showCalendar) {
                DiaperMonthView()
            }
            .confirmationDialog("Reset today's diapers?", isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Reset Day", role: .destructive) { resetToday() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will delete all of today's diaper logs.")
            }
            .background(LF.bg.ignoresSafeArea())
        }
    }

    // MARK: Quick Add
    private var quickAddCard: some View {
        Card {
            CardHeader(title: "Quick Add")
            HStack(spacing: 12) {
                CapsuleButton(title: "Wet", systemName: "drop.fill") { add(kind: "wet") }
                CapsuleButton(title: "Dirty", systemName: "trash.fill") { add(kind: "dirty") }
                CapsuleButton(title: "Both", systemName: "trash.circle.fill") { add(kind: "both") }
                    .buttonStyle(.bordered)
            }
            .controlSize(.regular)
            .lineLimit(1)
        }
    }

    // MARK: Today
    private var todayCard: some View {
        Card {
            CardHeader(title: "Today")
            let list = todayEvents()
            if list.isEmpty {
                Text("No diapers yet today.")
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(list.enumerated()), id: \.element.id) { idx, e in
                        HStack {
                            if e.kind == "both" {
                                HStack(spacing: 4) {
                                    Image(systemName: "drop.fill").foregroundStyle(.blue)
                                    Image(systemName: "trash.fill").foregroundStyle(.orange)
                                }
                                Text("Both")
                            } else {
                                Label(e.kind.capitalized, systemImage: e.kind == "wet" ? "drop.fill" : "trash.fill")
                            }
                            Spacer()
                            Text(timeOnly(e.time))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        .padding(.vertical, 8)
                        if idx < list.count - 1 { Divider().opacity(0.15) }
                    }
                }
                let wet = list.filter { $0.kind == "wet" || $0.kind == "both" }.count
                let dirty = list.filter { $0.kind == "dirty" || $0.kind == "both" }.count
                HStack {
                    Label("Wet: \(wet)", systemImage: "drop.fill")
                    Spacer()
                    Label("Dirty: \(dirty)", systemImage: "trash.fill")
                }
                .font(.callout)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
            }
        }
    }

    // MARK: Recent Days
    private var recentCard: some View {
        Card {
            CardHeader(title: "Recent Days")
            let days = recentDays()
            VStack(spacing: 0) {
                ForEach(Array(days.enumerated()), id: \.offset) { idx, day in
                    let c = counts(for: day)
                    HStack {
                        Text(dayString(day))
                        Spacer()
                        Label("\(c.wet)", systemImage: "drop.fill")
                        Label("\(c.dirty)", systemImage: "trash.fill")
                    }
                    .padding(.vertical, 8)
                    if idx < days.count - 1 { Divider().opacity(0.15) }
                }
            }
        }
    }

    // MARK: Actions
    private func add(kind: String) {
        let event = DiaperEvent(kind: kind, time: .now, mom: activeMom)
        context.insert(event)
        try? context.save()

        fallKind = kind
        fallID = UUID()
        let width = UIScreen.main.bounds.width
        fallX = CGFloat.random(in: 60...(width - 60))
        fallStart = -120
        fallEnd = max(140, containerHeight - 160)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            withAnimation(.easeOut(duration: 0.25)) { fallID = nil }
        }
    }

    private func resetToday() {
        let list = todayEvents()
        for e in list { context.delete(e) }
        try? context.save()
    }

    // MARK: Helpers
    private func todayEvents() -> [DiaperEvent] {
        let cal = Calendar.current
        return eventsForMom.filter { cal.isDate($0.time, inSameDayAs: Date()) }
    }

    private func recentDays() -> [Date] {
        let cal = Calendar.current
        return (0..<7).compactMap { cal.date(byAdding: .day, value: -$0, to: cal.startOfDay(for: Date())) }
    }

    private func counts(for day: Date) -> (wet: Int, dirty: Int) {
        let cal = Calendar.current
        let arr = eventsForMom.filter { cal.isDate($0.time, inSameDayAs: day) }
        let wet = arr.filter { $0.kind == "wet" || $0.kind == "both" }.count
        let dirty = arr.filter { $0.kind == "dirty" || $0.kind == "both" }.count
        return (wet, dirty)
    }

    private func dayString(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "EEE M/d"; return f.string(from: d)
    }

    private func timeOnly(_ d: Date) -> String {
        let f = DateFormatter(); f.timeStyle = .short; return f.string(from: d)
    }
}

// MARK: - DiaperMonthView
struct DiaperMonthView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var activeProfileStore: ActiveProfileStore
    @Query(sort: [SortDescriptor(\MomProfile.createdAt, order: .reverse)]) private var profiles: [MomProfile]
    @Query(sort: [SortDescriptor(\DiaperEvent.time, order: .reverse)]) private var allEvents: [DiaperEvent]
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

    private var events: [DiaperEvent] {
        allEvents.filter { $0.mom?.id == activeMom?.id }
    }

    private var monthEvents: [DiaperEvent] {
        events.filter { $0.time >= monthStart && $0.time < monthEnd }
    }

    private var groupedByDay: [Date: [DiaperEvent]] {
        Dictionary(grouping: monthEvents) { cal.startOfDay(for: $0.time) }
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
    private var noDirtyDays: Int {
        daysInMonth.filter { day in
            let d = groupedByDay[day] ?? []
            return d.filter { $0.kind == "dirty" || $0.kind == "both" }.isEmpty
        }.count
    }

    private func counts(for day: Date) -> (total: Int, wet: Int, dirty: Int) {
        let arr = groupedByDay[day] ?? []
        let wet = arr.filter { $0.kind == "wet" || $0.kind == "both" }.count
        let dirty = arr.filter { $0.kind == "dirty" || $0.kind == "both" }.count
        return (arr.count, wet, dirty)
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
                        Text("\(c.wet)/\(c.dirty)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
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
            CardHeader(title: "High Score")
            VStack(alignment: .leading, spacing: 4) {
                if let high = highScoreDay {
                    let c = counts(for: high)
                    Text("Most changes: \(dayString(high)) (\(c.total))")
                }
                if let low = lowScoreDay {
                    let c = counts(for: low)
                    Text("Least changes: \(dayString(low)) (\(c.total))")
                }
                Text("No dirty days: \(noDirtyDays)")
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

// MARK: - Falling Icon
private struct FallingIcon: View {
    let kind: String
    let x: CGFloat
    let startY: CGFloat
    let endY: CGFloat
    @State private var y: CGFloat = -120

    var body: some View {
        GeometryReader { _ in
            icon
                .position(x: x, y: y)
                .onAppear {
                    y = startY
                    DispatchQueue.main.async {
                        withAnimation(.interpolatingSpring(mass: 0.22, stiffness: 70, damping: 9, initialVelocity: 0.4)) {
                            y = endY
                        }
                    }
                }
        }
        .ignoresSafeArea()
    }

    @ViewBuilder private var icon: some View {
        if kind == "wet" {
            Image(systemName: "drop.fill").font(.system(size: 44))
                .foregroundStyle(.blue)
        } else {
            Image(systemName: "trash.fill").font(.system(size: 44))
                .foregroundStyle(.orange)
        }
    }
}
