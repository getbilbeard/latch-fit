import SwiftUI
import SwiftData

struct NutritionDashboardView: View {
    @Environment(\.modelContext) private var context
    @Query var todaysMeals: [MealItem]
    @Query var todaysLog: [DayNutritionLog]

    // Placeholder: wire real goal/exercise/steps when available
    var baseCalGoal: Double = 2210
    var exerciseToday: Double = 251
    var steps: Int = 6365
    var stepsGoal: Int = 10000
    var exerciseMinutes: Int = 33

    init() {
        let start = Calendar.current.startOfDay(for: Date())
        let mealsPred = #Predicate<MealItem> { $0.date >= start }
        _todaysMeals = Query(filter: mealsPred, sort: \.date, order: .forward)

        let logPred = #Predicate<DayNutritionLog> { $0.date == start }
        _todaysLog = Query(filter: logPred)
    }

    private var foodToday: Double {
        todaysMeals.reduce(0) { $0 + $1.calories }
    }

    private var consumedNet: Double { max(0, foodToday - exerciseToday) }
    private var remaining: Double { max(0, baseCalGoal - consumedNet) }
    private var progress: CGFloat {
        baseCalGoal <= 0 ? 0 : CGFloat(consumedNet / baseCalGoal)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    searchField

                    DashboardCard {
                        HStack(spacing: 18) {
                            ZStack {
                                RingProgressView(progress: progress)
                                    .frame(width: 140, height: 140)
                                RingCenterLabel(title: "Remaining",
                                                valueText: String(Int(remaining)),
                                                subtitle: "kcal")
                            }
                            VStack(alignment: .leading, spacing: 10) {
                                row(icon: "flag", title: "Base Goal", value: Int(baseCalGoal))
                                row(icon: "fork.knife", title: "Food", value: Int(foodToday))
                                row(icon: "flame", title: "Exercise", value: Int(exerciseToday))
                                Spacer(minLength: 0)
                            }
                        }
                    }

                    HStack(spacing: 12) {
                        DashboardCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Steps").font(.smallLabel).foregroundStyle(.secondary)
                                Text("\(steps)").font(.title2.weight(.semibold)).foregroundStyle(Color.lfInk)
                                ProgressView(value: min(1, Double(steps) / Double(max(1, stepsGoal))))
                                    .tint(.lfSageDeep)
                            }
                        }
                        DashboardCard {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Exercise").font(.smallLabel).foregroundStyle(.secondary)
                                HStack {
                                    Image(systemName: "flame.fill").foregroundStyle(.lfAmber)
                                    Text("\(Int(exerciseToday)) cal").font(.headline).foregroundStyle(Color.lfInk)
                                }
                                Text(String(format: "%02d:%02d hr", exerciseMinutes / 60, exerciseMinutes % 60))
                                    .font(.smallLabel).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(Color.lfCanvasBG)
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Image(systemName: "gearshape").foregroundStyle(Color.lfSageDeep)
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.lfCanvasBG, for: .navigationBar)
        }
        .tint(.lfSageDeep)
    }

    private func row(icon: String, title: String, value: Int) -> some View {
        HStack {
            Image(systemName: icon).foregroundStyle(.secondary)
            Text(title).foregroundStyle(.secondary)
            Spacer()
            Text("\(value)").foregroundStyle(Color.lfInk)
        }.font(.smallLabel)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundStyle(Color.lfMutedText)
            Text("Search for a food").foregroundStyle(Color.lfMutedText)
            Spacer()
        }
        .padding(.vertical, 12).padding(.horizontal, 14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.lfCardBG))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.black.opacity(0.04), lineWidth: 1))
    }
}
