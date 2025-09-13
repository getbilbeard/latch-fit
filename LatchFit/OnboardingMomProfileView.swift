import SwiftUI
import SwiftData
import UIKit

struct OnboardingMomProfileView: View {
    var editingProfile: MomProfile? = nil
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\MomProfile.createdAt, order: .reverse)]) private var profiles: [MomProfile]
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @EnvironmentObject private var activeProfileStore: ActiveProfileStore

    // MARK: - First‑run friendly state (blank until user enters)
    @State private var momName: String = ""
    @State private var childrenStr: String = ""
    @State private var activity: String? = nil
    @State private var ageStr: String = ""
    @State private var heightCmStr: String = ""
    @State private var weightLbStr: String = ""
    @State private var pace: String? = nil
    @State private var waterGoalText: String = ""
    @State private var mealsStr: String = ""
    @State private var breastfeeding: String? = nil
    @State private var suggestionText: String = ""

    // Units & focus
    enum HeightUnit: String, CaseIterable { case cm = "cm", ftin = "ft/in" }
    enum WeightUnit: String, CaseIterable { case lb = "lb", kg = "kg" }

    @State private var heightUnit: HeightUnit = .ftin
    @State private var weightUnit: WeightUnit = .lb

    @State private var heightFtStr: String = ""
    @State private var heightInStr: String = ""

    enum FieldFocus: Hashable { case age, heightCm, heightFt, heightIn, weight, water, meals, children }
    @FocusState private var focus: FieldFocus?

    @State private var validationMessage: String? = nil

    private var waterGoal: Int { Int(waterGoalText.filter(\.isNumber)) ?? 0 }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Hero / Welcome
                    WelcomeHero()
                        .padding(.horizontal, 20)

                    // ABOUT YOU
                    Card {
                        CardHeader(title: "About you")
                        VStack(spacing: 12) {
                            TextField("Your name", text: $momName)
                                .textContentType(.name)
                                .submitLabel(.next)

                            TextField("Number of children", text: $childrenStr)
                                .keyboardType(.numberPad)
                                .submitLabel(.next)

                            HStack {
                                Text("Activity")
                                Spacer()
                                Picker("Activity", selection: Binding(get: { activity ?? "" }, set: { activity = $0.isEmpty ? nil : $0 })) {
                                    Text("Select…").tag("")
                                    Text("Sedentary").tag("sedentary")
                                    Text("Light").tag("light")
                                    Text("Moderate").tag("moderate")
                                }
                                .pickerStyle(.menu)
                            }
                        }
                    }

                    // METRICS
                    Card {
                        CardHeader(title: "Metrics")
                        VStack(spacing: 12) {
                            TextField("Age (years)", text: $ageStr)
                                .keyboardType(.numberPad)
                                .focused($focus, equals: .age)

                            // Height with unit toggle
                            HStack(spacing: 12) {
                                Text("Height")
                                Spacer()
                                Picker("Height Unit", selection: $heightUnit) {
                                    Text("ft/in").tag(HeightUnit.ftin)
                                    Text("cm").tag(HeightUnit.cm)
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 140)
                            }
                            if heightUnit == .cm {
                                TextField("Height (cm)", text: $heightCmStr)
                                    .keyboardType(.numberPad)
                                    .focused($focus, equals: .heightCm)
                            } else {
                                HStack(spacing: 12) {
                                    TextField("ft", text: $heightFtStr)
                                        .keyboardType(.numberPad)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 70)
                                        .focused($focus, equals: .heightFt)

                                    TextField("in", text: $heightInStr)
                                        .keyboardType(.numberPad)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 70)
                                        .focused($focus, equals: .heightIn)
                                }
                            }

                            // Weight with unit toggle
                            HStack(spacing: 12) {
                                Text("Weight")
                                Spacer()
                                Picker("Weight Unit", selection: $weightUnit) {
                                    Text("lb").tag(WeightUnit.lb)
                                    Text("kg").tag(WeightUnit.kg)
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 110)
                            }
                            TextField(weightUnit == .lb ? "Weight (lb)" : "Weight (kg)", text: $weightLbStr)
                                .keyboardType(.decimalPad)
                                .focused($focus, equals: .weight)
                        }
                    }

                    // GOALS
                    Card {
                        CardHeader(title: "Goals")
                        VStack(spacing: 12) {
                            HStack {
                                Text("Weekly loss")
                                Spacer()
                                Picker("Weekly loss", selection: Binding(get: { pace ?? "maintain" }, set: { pace = $0 })) {
                                    Text("Maintain").tag("maintain")
                                    Text("0.25 lb / wk").tag("lose025")
                                    Text("0.5 lb / wk").tag("lose05")
                                }
                                .pickerStyle(.menu)
                            }
                            TextField("Water goal (oz)", text: $waterGoalText)
                                .keyboardType(.numberPad)
                                .focused($focus, equals: .water)
                            TextField("Meals per day", text: $mealsStr)
                                .keyboardType(.numberPad)
                            HStack {
                                Text("Breastfeeding")
                                Spacer()
                                Picker("Breastfeeding", selection: Binding(get: { breastfeeding ?? "" }, set: { breastfeeding = $0.isEmpty ? nil : $0 })) {
                                    Text("Select…").tag("")
                                    Text("Exclusive").tag("exclusive")
                                    Text("Partial").tag("partial")
                                    Text("Weaning").tag("weaning")
                                }
                                .pickerStyle(.menu)
                            }
                        }
                    }

                    Card {
                        CardHeader(title: "What I suggest", subtitle: "Based on your entries so far")
                        Text(suggestionText.isEmpty ? "Start filling things in above and I’ll suggest a gentle plan that protects milk supply." : suggestionText)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    // Primary CTA
                    if let message = validationMessage {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    Button(action: saveProfile) {
                        Text("Let’s begin your journey 💪👶")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(waterGoal <= 0)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
                .padding(.top, 8)
            }
            .navigationTitle("Welcome to LatchFit")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", action: handleClose)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { UIApplication.shared.endEditing() }
                }
            }
            .background(LF.bg.ignoresSafeArea())
            .scrollContentBackground(.hidden)
        }
        .onAppear {
            if let p = editingProfile {
                prefill(from: p)
            }
            updateSuggestion()

            // Initialize dual height fields from cm if present
            if let cm = Double(heightCmStr), cm > 0 {
                let h = cmToFtIn(cm)
                heightFtStr = h.ft == 0 ? "" : String(h.ft)
                heightInStr = h.inch == 0 ? "" : String(h.inch)
            }
            // If user prefers kg, convert display from saved lb
            if weightUnit == .kg, let lb = Double(weightLbStr), lb > 0 {
                weightLbStr = String(Int(lbToKg(lb).rounded()))
            }
        }
        .onChange(of: activity, initial: false) { _, _ in updateSuggestion() }
        .onChange(of: ageStr, initial: false) { _, _ in updateSuggestion() }
        .onChange(of: heightCmStr, initial: false) { _, _ in updateSuggestion() }
        .onChange(of: weightLbStr, initial: false) { _, _ in updateSuggestion() }
        .onChange(of: pace, initial: false) { _, _ in updateSuggestion() }
        .onChange(of: waterGoalText, initial: false) { _, _ in updateSuggestion() }
        .onChange(of: mealsStr, initial: false) { _, _ in updateSuggestion() }
        .onChange(of: breastfeeding, initial: false) { _, _ in updateSuggestion() }
        .onChange(of: heightUnit, initial: false) { _, newUnit in
            if newUnit == .cm {
                let ft = Int(heightFtStr) ?? 0
                let inch = Int(heightInStr) ?? 0
                let cm = ftInToCm(ft: ft, inch: inch)
                heightCmStr = cm > 0 ? String(Int(cm.rounded())) : ""
            } else {
                let cm = Double(heightCmStr) ?? 0
                let h = cmToFtIn(cm)
                heightFtStr = h.ft == 0 ? "" : String(h.ft)
                heightInStr = h.inch == 0 ? "" : String(h.inch)
            }
            updateSuggestion()
        }
        .onChange(of: weightUnit, initial: false) { _, newUnit in
            if newUnit == .kg {
                if let lb = Double(weightLbStr) {
                    weightLbStr = String(Int(lbToKg(lb).rounded()))
                }
            } else {
                if let kg = Double(weightLbStr) {
                    weightLbStr = String(Int(kgToLb(kg).rounded()))
                }
            }
            updateSuggestion()
        }
    }

    // MARK: - Prefill when editing only
    private func prefill(from p: MomProfile) {
        momName = p.momName
        childrenStr = String(p.numberOfChildren)
        activity = p.activityLevel
        ageStr = String(p.age)
        heightCmStr = String(Int(p.heightCm))
        let h = cmToFtIn(p.heightCm)
        heightFtStr = h.ft == 0 ? "" : String(h.ft)
        heightInStr = h.inch == 0 ? "" : String(h.inch)
        
        weightLbStr = String(Int((p.currentWeightLb > 0 ? p.currentWeightLb : p.startWeightLb)))
        pace = p.goalPace
        waterGoalText = String(p.waterGoalOz)
        mealsStr = String(p.mealsPerDay)
        breastfeeding = p.breastfeedingStatus
    }

    private func updateSuggestion() {
        // Parse inputs; if missing critical fields, clear suggestion.
        guard
            let bf = breastfeeding,
            let act = activity,
            let age = Int(ageStr),
            let h = Double(heightCmStr),
            let wLb = Double(weightLbStr),
            let meals = Int(mealsStr),
            let water = Int(waterGoalText.filter(\.isNumber))
        else {
            suggestionText = ""
            return
        }

        // Convert
        let wKg = wLb * 0.453592
        let bmr = (10 * wKg) + (6.25 * h) - (5 * Double(age)) - 161 // female variant

        let activityFactor: Double = {
            switch act {
            case "sedentary": return 1.3
            case "light":     return 1.45
            case "moderate":  return 1.6
            default:           return 1.45
            }
        }()

        var maintenance = max(1400, bmr * activityFactor)

        // Breastfeeding extra energy (very conservative)
        let bfExtra: Double = (bf == "exclusive") ? 400 : (bf == "partial" ? 250 : 100)
        maintenance += bfExtra

        let choice = pace ?? "maintain"
        let weeklyDeficit: Double = (choice == "lose05") ? 1750.0 : (choice == "lose025" ? 875.0 : 0.0)
        let target = max(1800.0, maintenance - (weeklyDeficit / 7.0))

        let protein = Int((1.6 * wKg).rounded())
        let paceText: String = {
            switch choice {
            case "lose05": return "lose ~0.5 lb/week"
            case "lose025": return "lose ~0.25 lb/week"
            default: return "maintain weight"
            }
        }()

        suggestionText = "I’d aim to \(paceText) around \(Int(target)) kcal/day, ~\(protein) g protein, \(meals) meals, and \(water) oz water. This keeps things gentle for breastfeeding (\(bf)). You can change pace anytime."
    }

    // MARK: - Unit conversion helpers
    private func cmToFtIn(_ cm: Double) -> (ft: Int, inch: Int) {
        guard cm > 0 else { return (0, 0) }
        let totalInches = cm / 2.54
        let ft = Int(totalInches / 12.0)
        let inch = Int((totalInches - Double(ft) * 12.0).rounded())
        return (ft, min(inch, 11))
    }

    private func ftInToCm(ft: Int, inch: Int) -> Double {
        let totalInches = Double(ft) * 12.0 + Double(inch)
        return totalInches * 2.54
    }

    private func lbToKg(_ lb: Double) -> Double { lb * 0.453592 }
    private func kgToLb(_ kg: Double) -> Double { kg / 0.453592 }

    // MARK: - Save / Validate
    private func saveProfile() {
        // Validation & parsing
        guard !momName.trimmingCharacters(in: .whitespaces).isEmpty else { show("Please enter your name"); return }
        guard let children = Int(childrenStr), children > 0 else { show("Enter number of children"); return }
        guard let act = activity else { show("Select your activity level"); return }
        guard let age = Int(ageStr), (16...60).contains(age) else { show("Enter age 16–60"); return }

        // Normalize height to cm
        let heightCm: Double = {
            switch heightUnit {
            case .cm:
                return Double(heightCmStr) ?? 0
            case .ftin:
                let ft = Int(heightFtStr) ?? 0
                let inch = Int(heightInStr) ?? 0
                return ftInToCm(ft: ft, inch: inch)
            }
        }()
        guard (120...210).contains(heightCm) else { show("Enter a valid height (120–210 cm or equivalent)."); return }

        // Normalize weight to lb
        let weightLb: Double = {
            if weightUnit == .lb { return Double(weightLbStr) ?? 0 }
            let kg = Double(weightLbStr) ?? 0
            return kgToLb(kg)
        }()
        guard (80...400).contains(weightLb) else { show("Enter a valid weight (80–400 lb or equivalent)."); return }

        guard let gp = pace else { show("Pick a goal pace"); return }
        let water = Int(waterGoalText.filter(\.isNumber)) ?? 0
        guard water > 0 else { show("Enter water goal (oz)"); return }
        guard let meals = Int(mealsStr), (3...6).contains(meals) else { show("Enter meals per day (3–6)"); return }
        guard let bf = breastfeeding else { show("Select breastfeeding status"); return }

        let profile: MomProfile
        if let existing = editingProfile {
            existing.momName = momName
            existing.numberOfChildren = children
            existing.activityLevel = act
            existing.age = age
            existing.heightCm = heightCm
            existing.currentWeightLb = weightLb
            existing.goalPace = gp

            existing.waterGoalOz = water
            existing.mealsPerDay = meals
            existing.breastfeedingStatus = bf
            if existing.nutritionGoals == nil {
                existing.nutritionGoals = NutritionGoals()
            }
            profile = existing
        } else {
            let p = MomProfile(
                createdAt: .now,
                momName: momName,
                numberOfChildren: children,
                babyName: "",
                babyDOB: .now,
                breastfeedingStatus: bf,
                activityLevel: act,
                age: age,
                heightCm: heightCm,
                currentWeightLb: weightLb,
                goalPace: gp,
                startWeightLb: weightLb,
                goalWeightLb: nil,
                waterGoalOz: water,
                calorieFloor: 1800,
                mealsPerDay: meals,
                dietaryPreference: "Omnivore",
                allergies: "",
                nutritionGoals: NutritionGoals()
            )
            context.insert(p)
            profile = p
        }

        try? context.save()
        activeProfileStore.setActive(profile.id.uuidString)
        hasCompletedOnboarding = true
        validationMessage = nil
        dismiss()
    }

    private func show(_ msg: String) {
        validationMessage = msg
    }

    private func handleClose() {
        if profiles.isEmpty {
            show("Please create a profile to continue")
        } else {
            hasCompletedOnboarding = true
            dismiss()
        }
    }
}

// MARK: - Cute Welcome Hero
private struct WelcomeHero: View {
    var body: some View {
        VStack(spacing: 12) {
            // If you have a Lottie named "welcome", use it; otherwise fallback to SF Symbols
            if let _ = Bundle.main.path(forResource: "welcome", ofType: "json") {
                // Replace with your Lottie wrapper if desired
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.pink)
                    .padding(6)
            } else {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.pink)
                    .padding(6)
            }
            Text("You’re doing something amazing 💙")
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)
            Text("We’ll personalize gentle guidance that protects your milk supply and fits your goals. A few quick questions — then you’re set!")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 8)
    }
}
