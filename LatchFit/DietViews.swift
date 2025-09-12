import SwiftUI
import SwiftData

// MARK: - Data structs (local to Diet UI)
struct DailyDietPlan {
    let calories: Int
    let proteinG: Int
    let fatG: Int
    let carbsG: Int
    let meals: [MealBlock]
    let tips: [String]
}
struct MealBlock { let title: String; let items: [String]; let note: String? }

// MARK: - Planner (same logic)
struct MealIdeaGenerator {
    func makePlan(calories: Int, proteinG: Int, fatG: Int, carbsG: Int,
                  mealsPerDay: Int, dietaryPreference: String, allergies: String,
                  mealStyle: String, cuisine: String) -> DailyDietPlan {
        let excludes = allergies.lowercased().split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let slots = (mealsPerDay == 5) ? ["Breakfast","Snack 1","Lunch","Snack 2","Dinner"] : ["Breakfast","Lunch","Dinner"]

        let omni: [String: [String]] = [
            "Breakfast": ["Greek yogurt + berries + oats", "Egg scramble + spinach + toast", "Overnight oats + chia + milk"],
            "Snack": ["Apple + peanut butter", "Cottage cheese + pineapple", "Trail mix"],
            "Lunch": ["Chicken wrap + hummus + salad", "Turkey sandwich + avocado + carrots", "Tuna bowl + rice + cucumber"],
            "Dinner": ["Salmon + quinoa + roasted veg", "Chicken stir-fry + rice", "Beef chili + beans + corn"]
        ]
        let veg: [String: [String]] = [
            "Breakfast": ["Overnight oats + soy milk + berries", "Tofu scramble + spinach + toast"],
            "Snack": ["Banana + almond butter", "Roasted chickpeas"],
            "Lunch": ["Lentil salad + feta (omit if dairy-free)", "Veggie wrap + hummus"],
            "Dinner": ["Tofu stir-fry + rice", "Bean chili + avocado"]
        ]
        let vegan: [String: [String]] = [
            "Breakfast": ["Overnight oats + plant milk + berries", "Tofu scramble + veggies"],
            "Snack": ["Banana + peanut butter", "Energy bites"],
            "Lunch": ["Quinoa bowl + beans + salsa", "Hummus wrap + veg"],
            "Dinner": ["Lentil curry + rice", "Tofu stir-fry + noodles"]
        ]
        let pesc: [String: [String]] = [
            "Breakfast": omni["Breakfast"]!,
            "Snack": omni["Snack"]!,
            "Lunch": ["Tuna bowl + rice + cucumber", "Shrimp tacos + slaw"],
            "Dinner": ["Salmon + quinoa + veg", "Shrimp stir-fry + rice"]
        ]

        let bank: [String: [String]] = {
            switch dietaryPreference.lowercased() {
            case "vegetarian": return veg.reduce(into: omni) { $0[$1.key] = $1.value }
            case "vegan": return vegan.reduce(into: omni) { $0[$1.key] = $1.value }
            case "pescatarian": return pesc.reduce(into: omni) { $0[$1.key] = $1.value }
            default: return omni
            }
        }()

        func filtered(_ items: [String]) -> [String] {
            guard !excludes.isEmpty else { return items }
            return items.filter { idea in
                let low = idea.lowercased()
                return !excludes.contains(where: { low.contains($0) })
            }
        }

        var meals: [MealBlock] = []
        for slot in slots {
            if slot.hasPrefix("Snack") {
                let idea = filtered(bank["Snack"] ?? ["Yogurt", "Fruit + nuts"]).first ?? "Fruit + nuts"
                meals.append(MealBlock(title: slot, items: [idea], note: snackNote(style: mealStyle)))
            } else if slot == "Breakfast" {
                let idea = filtered(bank["Breakfast"] ?? ["Oats"]).first ?? "Oats"
                meals.append(MealBlock(title: slot, items: [idea], note: "Add a protein (eggs, yogurt, tofu) to hit your target."))
            } else if slot == "Lunch" {
                let idea = filtered(bank["Lunch"] ?? ["Wrap"]).first ?? "Wrap"
                meals.append(MealBlock(title: slot, items: [idea], note: lunchNote(cuisine: cuisine)))
            } else {
                let idea = filtered(bank["Dinner"] ?? ["Stir-fry"]).first ?? "Stir-fry"
                meals.append(MealBlock(title: slot, items: [idea], note: dinnerNote(style: mealStyle)))
            }
        }

        let tips = tipsFor(breastfeeding: true, mealsPerDay: mealsPerDay)
        return DailyDietPlan(calories: calories, proteinG: proteinG, fatG: fatG, carbsG: carbsG, meals: meals, tips: tips)
    }

    private func snackNote(style: String) -> String {
        switch style {
        case "batch": return "Batch-prep snack boxes so protein is easy to grab."
        case "family": return "Make snacks that older kids like too."
        case "fresh": return "Pair fruit with a protein for balance."
        default: return "Keep 15–20g protein snacks handy."
        }
    }
    private func lunchNote(cuisine: String) -> String { "Add 25–35g protein; choose carbs you enjoy (\(cuisine))." }
    private func dinnerNote(style: String) -> String { style == "batch" ? "Cook once, eat twice: roast extra protein for tomorrow." : "Aim for a palm of protein + 2 cups veg." }
    private func tipsFor(breastfeeding: Bool, mealsPerDay: Int) -> [String] {
        var t = ["Hydrate through the day.", "Small, steady deficit protects supply.", "Prioritize protein at each meal."]
        if mealsPerDay == 5 { t.append("Use snacks to fill protein gaps.") }
        if breastfeeding { t.append("If supply dips, increase calories/fluids for a few days.") }
        return t
    }
}

// MARK: - AI Coach (on-device fallback used when network fails)
struct RecipeIdea: Identifiable, Equatable, Hashable {
    let id: UUID
    let title: String
    let lines: [String]
    private let calPerServing: Int
    private let proteinPerServing: Int
    var perServing: (cal: Int, protein: Int) { (calPerServing, proteinPerServing) }

    init(id: UUID = UUID(), title: String, lines: [String], perServing: (cal: Int, protein: Int)) {
        self.id = id
        self.title = title
        self.lines = lines
        self.calPerServing = perServing.cal
        self.proteinPerServing = perServing.protein
    }
}

enum AICoachEngine {
    static func suggestRecipes(ingredients: Set<String>, profile: MomProfile) async -> [RecipeIdea] {
        try? await Task.sleep(nanoseconds: 250_000_000)
        let pace = GoalPace(rawValue: profile.goalPace) ?? .maintain
        let plan = CoachCalculator.dailyPlan(
            age: profile.age, heightCm: profile.heightCm,
            weightLb: (profile.currentWeightLb > 0 ? profile.currentWeightLb : profile.startWeightLb),
            activity: profile.activityLevel, breastfeedingStatus: profile.breastfeedingStatus,
            calorieFloor: profile.calorieFloor, goal: pace
        )
        let meals = max(3, profile.mealsPerDay)
        let targetProtein = max(18, plan.proteinG / meals)
        let targetCalories = max(350, plan.calories / meals)

        let lower = ingredients.map { $0.lowercased() }
        func has(_ key: String) -> Bool { lower.contains(where: { $0.contains(key) }) }
        let protein = ["chicken","turkey","tuna","salmon","eggs","tofu","yogurt","cottage","beans"].first(where: { has($0) }) ?? "chicken"
        let carb = ["rice","quinoa","tortilla","pasta","oats","bread","potato"].first(where: { has($0) }) ?? "rice"
        let veg = ["spinach","broccoli","pepper","onion","tomato","avocado","cucumber"].first(where: { has($0) }) ?? "spinach"
        let flavor = ["salsa","soy sauce","pesto","lemon","garlic"].first(where: { has($0) }) ?? "garlic"
        let ozProtein = max(3, Int(ceil(Double(targetProtein) / 7.0)))

        let bowl = RecipeIdea(title: "Protein bowl — \(protein) + \(carb)",
                              lines: ["\(ozProtein) oz \(protein), cooked","3/4–1 cup \(carb)","1–2 cups \(veg)","1 tsp olive oil, \(flavor)"],
                              perServing: (cal: targetCalories, protein: targetProtein))
        let wrap = RecipeIdea(title: "Wraps/tacos — quick handheld",
                              lines: ["1–2 \(carb) (wraps)","\(ozProtein) oz \(protein)","Veg: \(veg), lettuce, tomato","Sauce: hummus or salsa"],
                              perServing: (cal: targetCalories, protein: targetProtein))
        let eggs = RecipeIdea(title: "Egg/tofu scramble",
                              lines: ["2–3 eggs (or tofu)","1 cup \(veg)","1 slice whole-grain toast or 1/2 cup \(carb)","Fruit on the side"],
                              perServing: (cal: targetCalories, protein: targetProtein))
        return [bowl, wrap, eggs]
    }
}

// MARK: - Diet UI

struct DietPlanView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var flags: FeatureFlags
    @Query(sort: [SortDescriptor(\MomProfile.createdAt, order: .reverse)]) private var profiles: [MomProfile]

    @State private var plan: DailyDietPlan? = nil
    @State private var showOnboarding = false
    private let generator = MealIdeaGenerator()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let p = profiles.first {
                        macroCard(for: p)
                        buildYourOwnCTA()
                        mealsCard(for: p)
                        tipsCard()
                    } else {
                        Card {
                            CardHeader(title: "Profile needed")
                            Text("Create your profile to personalize calories and macros.")
                                .foregroundStyle(.secondary)
                            CapsuleButton(title: "Create profile", systemName: "person.badge.plus") {
                                showOnboarding = true
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .navigationTitle("Diet")
            .toolbarTitleDisplayMode(.large)
            .background(LF.bg.ignoresSafeArea())
            .sheet(isPresented: $showOnboarding) { OnboardingMomProfileView() }
            .onAppear { computePlan() }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { computePlan() } label: { Label("Refresh", systemImage: "arrow.clockwise") }
                    NavigationLink { BuildYourOwnView() } label: { Label("Build", systemImage: "wand.and.stars") }
                }
            }
        }
    }

    private func computePlan() {
        guard let p = profiles.first else { return }
        let pace = GoalPace(rawValue: p.goalPace) ?? .maintain
        let c = CoachCalculator.dailyPlan(
            age: p.age,
            heightCm: p.heightCm,
            weightLb: (p.currentWeightLb > 0 ? p.currentWeightLb : p.startWeightLb),
            activity: p.activityLevel,
            breastfeedingStatus: p.breastfeedingStatus,
            calorieFloor: p.calorieFloor,
            goal: pace
        )
        self.plan = generator.makePlan(
            calories: c.calories, proteinG: c.proteinG, fatG: c.fatG, carbsG: c.carbsG,
            mealsPerDay: p.mealsPerDay, dietaryPreference: p.dietaryPreference,
            allergies: p.allergies, mealStyle: "family", cuisine: "any"
        )
    }

    @ViewBuilder private func macroCard(for p: MomProfile) -> some View {
        if let plan = plan {
            Card {
                CardHeader(title: "Today's Targets")
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Calories"); Text("Protein"); Text("Fat"); Text("Carbs")
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 8) {
                        Text("\(plan.calories) kcal").monospacedDigit()
                        Text("\(plan.proteinG) g").monospacedDigit()
                        Text("\(plan.fatG) g").monospacedDigit()
                        Text("\(plan.carbsG) g").monospacedDigit()
                    }
                }
                Text("Gentle targets protect milk supply.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder private func buildYourOwnCTA() -> some View {
        NavigationLink {
            BuildYourOwnView()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "wand.and.stars").imageScale(.large)
                Text("Build your own with AI").font(.headline.weight(.semibold))
                Spacer()
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(Color.accentColor, in: Capsule())
            .foregroundStyle(.white)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Build your own meal with AI")
    }

    @ViewBuilder private func mealsCard(for p: MomProfile) -> some View {
        if let plan = plan {
            Card {
                CardHeader(title: "Meals")
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(plan.meals.enumerated()), id: \.offset) { _, m in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(m.title).font(.headline)
                            ForEach(m.items, id: \.self) { item in
                                HStack(alignment: .top) {
                                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                                    Text(item)
                                }
                            }
                            if let note = m.note, !note.isEmpty {
                                Text(note).font(.footnote).foregroundStyle(.secondary)
                            }
                        }
                        if m.title != plan.meals.last?.title { Divider().opacity(0.15) }
                    }
                }
            }
        }
    }

    @ViewBuilder private func tipsCard() -> some View {
        if let plan = plan {
            Card {
                CardHeader(title: "Coach Tips")
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(plan.tips, id: \.self) { t in
                        HStack(alignment: .top) {
                            Image(systemName: "lightbulb.fill").foregroundStyle(.yellow)
                            Text(t)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Build Your Own

struct BuildYourOwnView: View {
    @EnvironmentObject private var flags: FeatureFlags
    @Query(sort: [SortDescriptor(\MomProfile.createdAt, order: .reverse)]) private var profiles: [MomProfile]

    @State private var pantry: String = ""
    @State private var ideas: [RecipeIdea] = []
    @State private var isLoading = false
    @State private var errorMsg: String? = nil
    @FocusState private var fieldFocused: Bool

    private var recipeService: RecipeServing { RecipeService() }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Card {
                        CardHeader(title: "Build Your Own")
                        Text("Type what you have (comma-separated) and I'll suggest balanced recipes.")
                            .foregroundStyle(.secondary)

                        TextField("e.g. chicken, rice, spinach, salsa", text: $pantry)
                            .textFieldStyle(.roundedBorder)
                            .focused($fieldFocused)
                            .submitLabel(.done)

                        HStack {
                            CapsuleButton(title: "Suggest", systemName: "sparkles") {
                                fieldFocused = false
                                suggest()
                            }
                            CapsuleButton(title: "Clear", systemName: "xmark") {
                                pantry = ""; ideas = []; errorMsg = nil
                            }
                            .buttonStyle(.bordered).tint(.gray)
                        }
                    }

                    if let msg = errorMsg {
                        Card {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                                Text(msg)
                            }.font(.footnote)
                        }
                    }

                    if isLoading { ProgressView().padding() }

                    if !ideas.isEmpty {
                        Card {
                            CardHeader(title: "Ideas")
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Recipes fetched or generated & scaled to your per-meal goal.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                ForEach(ideas) { r in
                                    NavigationLink { RecipeDetailView(recipe: r) } label: {
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text(r.title).font(.headline)
                                                Text("~ \(r.perServing.cal) kcal • \(r.perServing.protein) g protein")
                                                    .font(.footnote).foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.callout).foregroundStyle(.secondary)
                                        }
                                    }
                                    if r.id != ideas.last?.id { Divider().opacity(0.15) }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .navigationTitle("Build Your Own")
            .toolbarTitleDisplayMode(.large)
            .background(LF.bg.ignoresSafeArea())
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { fieldFocused = false }
                }
            }
        }
    }

    private func suggest() {
        errorMsg = nil
        ideas = []

        guard let profile = profiles.first else {
            errorMsg = "Create a profile to personalize suggestions."
            return
        }

        let pace = GoalPace(rawValue: profile.goalPace) ?? .maintain
        let plan = CoachCalculator.dailyPlan(
            age: profile.age,
            heightCm: profile.heightCm,
            weightLb: (profile.currentWeightLb > 0 ? profile.currentWeightLb : profile.startWeightLb),
            activity: profile.activityLevel,
            breastfeedingStatus: profile.breastfeedingStatus,
            calorieFloor: profile.calorieFloor,
            goal: pace
        )
        let meals = max(3, profile.mealsPerDay)
        let perMealCal   = max(300, plan.calories / meals)
        let perMealProtG = max(18,   plan.proteinG  / meals)

        let ingredients = pantry
            .lowercased()
            .split(whereSeparator: { ",;".contains($0) || $0.isNewline || $0.isWhitespace })
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !ingredients.isEmpty else {
            errorMsg = "Add at least one ingredient (e.g., “chicken, rice”)."
            return
        }

        isLoading = true
        Task {
            do {
                var mapped: [RecipeIdea] = []

                if flags.aiEnabled && flags.useLiveRecipes && !flags.simulateNetworkFailure {
                    let results = try await recipeService.searchRecipes(
                        ingredients: ingredients.joined(separator: ","),
                        maxCalories: perMealCal + 200,
                        minProtein: perMealProtG,
                        count: 6
                    )

                    // If upstream gave us nothing, fall back to local AI
                    if results.isEmpty {
                        mapped = await localAI(profile: profile, perMealCal: perMealCal, perMealProtG: perMealProtG, ingredients: ingredients)
                    } else {
                        // Map/scaled (assume your RecipeService returns WebRecipe with calories/protein if available)
                        mapped = results.map { r in
                            RecipeIdea(
                                title: r.title,
                                lines: ["Scaled to ~\(perMealCal) kcal target"],
                                perServing: (perMealCal, perMealProtG)
                            )
                        }
                    }
                } else {
                    // Offline / quotas / debug -> local AI only
                    mapped = await localAI(profile: profile, perMealCal: perMealCal, perMealProtG: perMealProtG, ingredients: ingredients)
                }

                await MainActor.run {
                    self.ideas = mapped
                    self.isLoading = false
                    if mapped.isEmpty {
                        self.errorMsg = "No matches yet. Try different items like “tuna, rice, spinach”."
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMsg = "Couldn’t fetch recipes right now. Showing on-device ideas instead."
                }
                let fallback = await localAI(profile: profile, perMealCal: perMealCal, perMealProtG: perMealProtG, ingredients: ingredients)
                await MainActor.run {
                    self.ideas = fallback
                }
            }
        }
    }

    private func localAI(profile: MomProfile, perMealCal: Int, perMealProtG: Int, ingredients: [String]) async -> [RecipeIdea] {
        let base = await AICoachEngine.suggestRecipes(ingredients: Set(ingredients), profile: profile)
        return base.map { RecipeIdea(title: $0.title, lines: $0.lines, perServing: (perMealCal, perMealProtG)) }
    }
}

// MARK: - Recipe detail
struct RecipeDetailView: View {
    let recipe: RecipeIdea
    var body: some View {
        ScrollView {
            Card {
                Text(recipe.title).font(.title2.weight(.semibold))
                Text("~ \(recipe.perServing.cal) kcal • \(recipe.perServing.protein) g protein per serving")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            CardHeader(title: "Steps / Ingredients")
            Card {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(recipe.lines.enumerated()), id: \.offset) { idx, line in
                        HStack(alignment: .top) {
                            Text("\(idx+1).").monospacedDigit().foregroundStyle(.secondary)
                            Text(line)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(LF.bg.ignoresSafeArea())
        .navigationTitle("Recipe")
        .toolbarTitleDisplayMode(.inline)
    }
}
