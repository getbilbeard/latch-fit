import SwiftUI
import SwiftData

// MARK: - BabyView (Diapers + History + Piles)
struct BabyView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\DiaperEvent.time, order: .reverse)])
    private var events: [DiaperEvent]

    @State private var showResetConfirm = false
    @State private var showConfetti = false

    // falling icon animation token
    @State private var fallID: UUID? = nil
    @State private var fallKind: String = "wet"
    @State private var fallStart: CGFloat = -120
    @State private var fallEnd: CGFloat = 900
    @State private var fallX: CGFloat = 0

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 16) {
                        // Quick add
                        Card {
                            CardHeader(title: "Quick Add")
                            HStack(spacing: 12) {
                                CapsuleButton(title: "Wet", systemName: "drop.fill") { logDiaper(kind: "wet") }
                                CapsuleButton(title: "Dirty", systemName: "trash.fill") { logDiaper(kind: "dirty") }
                                    .buttonStyle(.bordered)
                            }
                        }

                        // Today
                        Card {
                            CardHeader(title: "Today")
                            let today = todayEvents()
                            if today.isEmpty {
                                Text("No diapers yet today.")
                                    .foregroundStyle(.secondary)
                            } else {
                                // High score banner
                                let hs = highScore()
                                if hs > 0 {
                                    HStack {
                                        Image(systemName: "trophy.fill").foregroundStyle(.yellow)
                                        Text("High score: \(hs) in a day")
                                            .font(.subheadline.weight(.semibold))
                                        Spacer()
                                    }
                                    .padding(8)
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
                                }

                                VStack(spacing: 0) {
                                    ForEach(Array(today.enumerated()), id: \.element.id) { idx, e in
                                        HStack(alignment: .firstTextBaseline) {
                                            Label(e.kind.capitalized, systemImage: e.kind == "wet" ? "drop.fill" : "trash.fill")
                                            Spacer()
                                            Text(timeOnly(e.time)).monospacedDigit().foregroundStyle(.secondary)
                                        }
                                        .padding(.vertical, 8)
                                        if idx < today.count - 1 { Divider().opacity(0.15) }
                                    }
                                }

                                // Today totals row
                                let wet = today.filter { $0.kind == "wet" }.count
                                let dirty = today.filter { $0.kind == "dirty" }.count
                                HStack {
                                    Label("Wet: \(wet)", systemImage: "drop.fill")
                                    Spacer()
                                    Label("Dirty: \(dirty)", systemImage: "trash.fill")
                                }
                                .font(.callout).foregroundStyle(.secondary)
                                .padding(.top, 8)
                            }

                            HStack(spacing: 12) {
                                CapsuleButton(title: "Undo", systemName: "arrow.uturn.left") { undoLast() }
                                    .buttonStyle(.bordered).tint(.gray)
                                CapsuleButton(title: "Reset Today", systemName: "trash") { showResetConfirm = true }
                                    .buttonStyle(.bordered).tint(.red)
                            }
                            .padding(.top, 8)
                        }

                        Spacer(minLength: 64)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .safeAreaPadding(.bottom, 180)
                }

                // Falling icon overlay — shows briefly after each log
                if fallID != nil {
                    FallingIcon(kind: fallKind, x: fallX, startY: fallStart, endY: fallEnd)
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }
            }
            .safeAreaInset(edge: .bottom) {
                PilesBar(todayWet: todayCount(kind: "wet"), todayDirty: todayCount(kind: "dirty"))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Material.ultraThin,
                        in: Rectangle()
                    )
                    .shadow(color: .black.opacity(0.06), radius: 8, y: -2)
            }
            .withConfetti($showConfetti)
            .navigationTitle("Baby")
            .toolbarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        DiaperHistoryView()
                    } label: {
                        Label("Calendar", systemImage: "calendar")
                    }
                }
            }
            .background(LF.bg.ignoresSafeArea())
            .confirmationDialog("Reset today's diapers?", isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Reset Today", role: .destructive) { resetToday() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will delete all of today's diaper logs.")
            }
        }
    }

    // MARK: - Actions
    private func logDiaper(kind: String) {
        context.insert(DiaperEvent(time: .now, kind: kind))
        try? context.save()
        ActivityTracker.mark(.diaper, in: context)

        // haptic
        let g = UINotificationFeedbackGenerator(); g.notificationOccurred(.success)

        // simple fall animation
        fallKind = kind
        fallID = UUID()
        fallX = CGFloat.random(in: 60...UIScreen.main.bounds.width - 60)
        fallStart = -120
        fallEnd = UIScreen.main.bounds.height - 120 // land near piles
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            withAnimation(.easeOut(duration: 0.25)) { fallID = nil }
        }

        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            // trigger view updates smoothly
            _ = ()
        }

        // celebrate each 5 logs
        if (todayEvents().count % 5) == 0 {
            showConfetti = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { showConfetti = false }
        }
    }

    private func undoLast() {
        if let last = events.first, Calendar.current.isDateInToday(last.time) {
            context.delete(last)
            try? context.save()
        }
    }

    private func resetToday() {
        let today = todayEvents()
        for e in today { context.delete(e) }
        try? context.save()
    }

    // MARK: - Helpers
    private func todayEvents() -> [DiaperEvent] {
        let cal = Calendar.current
        return events.filter { cal.isDate($0.time, inSameDayAs: Date()) }
    }

    private func todayCount(kind: String) -> Int { todayEvents().filter { $0.kind == kind }.count }

    private func highScore() -> Int {
        // max diapers in any single day
        let cal = Calendar.current
        let dict = Dictionary(grouping: events) { cal.startOfDay(for: $0.time) }
        return dict.values.map { $0.count }.max() ?? 0
    }

    private func timeOnly(_ d: Date) -> String {
        let f = DateFormatter(); f.timeStyle = .short; return f.string(from: d)
    }
}

// MARK: - History (Calendar View)
struct DiaperHistoryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\DiaperEvent.time, order: .reverse)]) private var allEvents: [DiaperEvent]

    // Navigate months
    @State private var monthOffset = 0 // 0 = current month

    private var cal: Calendar { Calendar.current }

    // MARK: - Heatmap helpers and selection state
    // Heatmap scale (max changes in visible month)
    private var monthMax: Int { groupedByDay.values.map { $0.count }.max() ?? 0 }
    @State private var selectedDay: Date? = nil
    @State private var showDayDetail = false

    // MARK: - Derived month ranges
    private var monthStart: Date {
        let base = cal.date(byAdding: .month, value: monthOffset, to: Date()) ?? Date()
        let comps = cal.dateComponents([.year, .month], from: base)
        return cal.date(from: comps) ?? Date()
    }
    private var monthEnd: Date {
        cal.date(byAdding: .month, value: 1, to: monthStart) ?? monthStart
    }

    // Events in visible month
    private var monthEvents: [DiaperEvent] {
        allEvents.filter { $0.time >= monthStart && $0.time < monthEnd }
    }

    // Group by day
    private var groupedByDay: [Date: [DiaperEvent]] {
        Dictionary(grouping: monthEvents) { cal.startOfDay(for: $0.time) }
    }

    // Score analytics
    private var highScoreDay: Date? {
        groupedByDay.max { $0.value.count < $1.value.count }?.key
    }
    private var lowScoreDay: Date? {
        // minimum non‑zero day (if all zero, returns nil)
        let nonZero = groupedByDay.filter { !$0.value.isEmpty }
        return nonZero.min { $0.value.count < $1.value.count }?.key
    }

    private func counts(for day: Date) -> (total: Int, wet: Int, dirty: Int) {
        let arr = groupedByDay[day] ?? []
        let w = arr.filter { $0.kind == "wet" }.count
        let d = arr.filter { $0.kind == "dirty" }.count
        return (arr.count, w, d)
    }

    // Month grid helpers
    private var daysInMonth: [Date] {
        let range = cal.range(of: .day, in: .month, for: monthStart) ?? 1..<31
        return range.compactMap { day -> Date? in
            var comps = cal.dateComponents([.year, .month], from: monthStart)
            comps.day = day
            return cal.date(from: comps)
        }
    }
    private var leadingBlankCount: Int {
        // 1 = Sunday … 7 = Saturday; make grid start on Sunday
        let first = daysInMonth.first ?? monthStart
        let wk = cal.component(.weekday, from: first)
        return (wk - 1) // 0..6 blanks
    }

    private let cols: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        VStack(spacing: 12) {
            // Header with month title + nav styled like a segmented control
            HStack(spacing: 8) {
                Button { withAnimation(.spring()) { monthOffset -= 1 } } label: {
                    Image(systemName: "chevron.left").font(.title3.weight(.semibold))
                }
                .buttonStyle(.plain)

                Text(monthTitle(monthStart))
                    .font(.title2.weight(.bold))
                    .padding(.horizontal, 14).padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())

                Button { withAnimation(.spring()) { monthOffset += 1 } } label: {
                    Image(systemName: "chevron.right").font(.title3.weight(.semibold))
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 6)

            // Weekday symbols (monospaced for alignment)
            HStack {
                ForEach(cal.shortWeekdaySymbols, id: \.self) { s in
                    Text(s.uppercased())
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 16)

            // Calendar grid with heatmap and badges
            ScrollView {
                LazyVGrid(columns: cols, spacing: 10) {
                    // leading blanks
                    ForEach(0..<leadingBlankCount, id: \.self) { _ in
                        Color.clear.frame(height: 58)
                    }

                    ForEach(daysInMonth, id: \.self) { day in
                        let c = counts(for: day)
                        DayCell(
                            date: day,
                            isToday: cal.isDateInToday(day),
                            isHigh: (highScoreDay.map { cal.isDate($0, inSameDayAs: day) } ?? false),
                            isLow: (lowScoreDay.map { cal.isDate($0, inSameDayAs: day) } ?? false),
                            counts: c,
                            intensity: heat(for: c.total)
                        )
                        .onTapGesture {
                            selectedDay = day
                            showDayDetail = true
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }

            legend
                .padding(.horizontal)
                .padding(.bottom, 8)
        }
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .sheet(isPresented: $showDayDetail) {
            if let d = selectedDay {
                DayDetailSheet(date: d, items: groupedByDay[d] ?? [])
            }
        }
    }

    private func heat(for total: Int) -> Double {
        guard monthMax > 0 else { return 0 }
        // clamp 0.1...1 for non-zero, smoother gradient
        let v = Double(total) / Double(monthMax)
        return total == 0 ? 0 : max(0.12, min(1.0, v))
    }

    // Legend view
    private var legend: some View {
        HStack(spacing: 14) {
            Label("Most changes", systemImage: "star.fill").labelStyle(.iconOnly)
                .foregroundStyle(.yellow)
            Text("Most changes").font(.caption)
            Spacer()
            Image(systemName: "arrow.down.circle.fill").foregroundStyle(.blue)
            Text("Least (non‑zero)").font(.caption)
            Spacer()
            Image(systemName: "trash.slash.fill").foregroundStyle(.orange)
            Text("No dirty").font(.caption)
        }
    }

    // Helpers
    private func dayString(_ d: Date) -> String { let f = DateFormatter(); f.dateStyle = .medium; return f.string(from: d) }
    private func monthTitle(_ d: Date) -> String { let f = DateFormatter(); f.dateFormat = "LLLL yyyy"; return f.string(from: d) }
    private func timeOnly(_ d: Date) -> String { let f = DateFormatter(); f.timeStyle = .short; return f.string(from: d) }

    // MARK: - Day Cell
    private struct DayCell: View {
        let date: Date
        let isToday: Bool
        let isHigh: Bool
        let isLow: Bool
        let counts: (total: Int, wet: Int, dirty: Int)
        let intensity: Double // 0…1 for heat tint

        var body: some View {
            ZStack(alignment: .topLeading) {
                let baseTint = Color.blue
                let fill: Color = counts.total == 0
                    ? Color(.systemFill).opacity(0.30)
                    : baseTint.opacity(0.10 + 0.35 * intensity)

                RoundedRectangle(cornerRadius: 12)
                    .fill(fill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isToday ? baseTint.opacity(0.7) : .black.opacity(0.06), lineWidth: isToday ? 2 : 1)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 2, y: 1)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text("\(Calendar.current.component(.day, from: date))")
                            .font(.callout.weight(.semibold))
                        if isHigh { Image(systemName: "star.fill").foregroundStyle(.yellow) }
                        if isLow { Image(systemName: "arrow.down.circle.fill").foregroundStyle(.blue) }
                        if counts.dirty == 0 && counts.total > 0 { Image(systemName: "trash.slash.fill").foregroundStyle(.orange) }
                        Spacer()
                    }

                    Spacer(minLength: 2)

                    HStack(spacing: 6) {
                        if counts.total > 0 {
                            // wet/dirty mini dots
                            HStack(spacing: 3) {
                                Image(systemName: "drop.fill").font(.caption2).foregroundStyle(.blue)
                                Text("\(counts.wet)").font(.caption2)
                                Image(systemName: "trash.fill").font(.caption2).foregroundStyle(.orange)
                                Text("\(counts.dirty)").font(.caption2)
                            }
                            Spacer()
                            Text("\(counts.total)")
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(.white.opacity(0.85), in: Capsule())
                        } else {
                            Spacer()
                            Text("–").font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(8)
            }
            .frame(height: 58)
            .contentShape(Rectangle())
        }
    }

    // MARK: - Day detail sheet
    private struct DayDetailSheet: View {
        let date: Date
        let items: [DiaperEvent]
        private var dayTitle: String { let f = DateFormatter(); f.dateStyle = .full; return f.string(from: date) }
        private func timeOnly(_ d: Date) -> String {
            let f = DateFormatter(); f.timeStyle = .short; return f.string(from: d)
        }
        var body: some View {
            NavigationStack {
                List {
                    ForEach(items.sorted { $0.time > $1.time }, id: \.id) { e in
                        HStack {
                            Label(e.kind.capitalized, systemImage: e.kind == "wet" ? "drop.fill" : "trash.fill")
                            Spacer()
                            Text(timeOnly(e.time)).foregroundStyle(.secondary)
                        }
                    }
                }
                .navigationTitle(dayTitle)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) } } }
            }
        }
    }
}

// MARK: - Falling icon (lightweight)
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
                    withAnimation(.interpolatingSpring(mass: 0.2, stiffness: 60, damping: 8, initialVelocity: 0.5)) {
                        y = endY
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

// MARK: - Compact grid pile (no overlap)
private struct PileArea: View {
    let count: Int
    let systemName: String
    let tint: Color
    var columns: Int = 5
    var itemSize: CGFloat = 26
    var spacing: CGFloat = 6
    var maxRender: Int = 15

    var rows: Int {
        let c = min(count, maxRender)
        return max(1, Int(ceil(Double(c) / Double(columns))))
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Reserve footprint so sibling pile can't overlap
            Color.clear
                .frame(
                    width: CGFloat(columns) * itemSize + CGFloat(columns - 1) * spacing,
                    height: CGFloat(rows) * (itemSize + spacing)
                )

            // Tile icons
            ForEach(0..<min(count, maxRender), id: \.self) { idx in
                let col = idx % columns
                let row = idx / columns
                let stagger: CGFloat = 6
                Image(systemName: systemName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: itemSize, height: itemSize)
                    .foregroundStyle(tint)
                    .shadow(radius: 1, y: 1)
                    .offset(
                        x: CGFloat(col) * (itemSize + spacing) + CGFloat(row) * stagger,
                        y: -CGFloat(row) * (itemSize + spacing)
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            // +N badge when overflowing
            if count > maxRender {
                let extra = count - maxRender
                Text("+\(extra)")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().stroke(.white.opacity(0.7)))
                    .offset(
                        x: CGFloat((maxRender - 1) % columns) * (itemSize + spacing),
                        y: -CGFloat((maxRender - 1) / columns) * (itemSize + spacing) - 4
                    )
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: count)
        .accessibilityLabel(Text("\(count) items"))
    }
}

// MARK: - Piles Bar
private struct PilesBar: View {
    let todayWet: Int
    let todayDirty: Int

    var body: some View {
        HStack(alignment: .bottom) {
            // Wet (left)
            VStack(alignment: .leading, spacing: 6) {
                Text("Wet: \(todayWet)")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                PileArea(count: todayWet, systemName: "drop.fill", tint: .blue)
            }

            Spacer(minLength: 24)

            // Dirty (right)
            VStack(alignment: .trailing, spacing: 6) {
                Text("Dirty: \(todayDirty)")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                PileArea(count: todayDirty, systemName: "trash.fill", tint: .orange)
            }
        }
        .frame(height: 172)
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: todayWet)
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: todayDirty)
    }
}
