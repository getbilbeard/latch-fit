import Foundation
import SwiftData

// MARK: - Mom Profile

@Model
final class MomProfile {
    @Attribute(.unique) var id: UUID

    // bookkeeping
    var createdAt: Date

    // profile
    var momName: String
    var numberOfChildren: Int

    // baby
    var babyName: String
    var babyDOB: Date
    /// "exclusive", "partial", "weaning"
    var breastfeedingStatus: String

    // metrics
    var activityLevel: String      // "sedentary", "light", "moderate"
    var age: Int                   // years
    var heightCm: Double           // centimeters
    var currentWeightLb: Double    // pounds

    // goals
    /// "maintain", "lose025", "lose05"
    var goalPace: String
    var startWeightLb: Double
    var goalWeightLb: Double?

    // hydration
    var waterGoalOz: Int

    // diet
    var calorieFloor: Int
    var mealsPerDay: Int
    var dietaryPreference: String  // "Omnivore", "Vegetarian", "Vegan", ...
    var allergies: String          // comma-separated list

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        momName: String = "",
        numberOfChildren: Int = 1,
        babyName: String = "",
        babyDOB: Date = .now,
        breastfeedingStatus: String = "exclusive",
        activityLevel: String = "light",
        age: Int = 30,
        heightCm: Double = 165,
        currentWeightLb: Double = 150,
        goalPace: String = "maintain",
        startWeightLb: Double = 150,
        goalWeightLb: Double? = nil,
        waterGoalOz: Int = 96,
        calorieFloor: Int = 1800,
        mealsPerDay: Int = 3,
        dietaryPreference: String = "Omnivore",
        allergies: String = ""
    ) {
        self.id = id
        self.createdAt = createdAt
        self.momName = momName
        self.numberOfChildren = numberOfChildren
        self.babyName = babyName
        self.babyDOB = babyDOB
        self.breastfeedingStatus = breastfeedingStatus
        self.activityLevel = activityLevel
        self.age = age
        self.heightCm = heightCm
        self.currentWeightLb = currentWeightLb
        self.goalPace = goalPace
        self.startWeightLb = startWeightLb
        self.goalWeightLb = goalWeightLb
        self.waterGoalOz = waterGoalOz
        self.calorieFloor = calorieFloor
        self.mealsPerDay = mealsPerDay
        self.dietaryPreference = dietaryPreference
        self.allergies = allergies
    }
}

// MARK: - Pumping / Milk / Water / Diapers / Weight

@Model
final class PumpSession {
    @Attribute(.unique) var id: UUID
    var date: Date
    var volumeOz: Double
    // Persist side as a simple string for schema stability: "left", "right", "both"
    var sideRaw: String
    var note: String?
    var durationSec: Int?
    /// "nursing" or "pumping"
    var mode: String?

    init(id: UUID = UUID(),
         date: Date = .now,
         volumeOz: Double,
         sideRaw: String = "both",
         note: String? = nil,
         durationSec: Int? = nil,
         mode: String? = nil) {
        self.id = id
        self.date = date
        self.volumeOz = volumeOz
        self.sideRaw = sideRaw
        self.note = note
        self.durationSec = durationSec
        self.mode = mode
    }

    // Convenience typed accessor (not persisted)
    enum BreastSide: String, Codable, CaseIterable { case left, right, both }

    var side: BreastSide {
        get { BreastSide(rawValue: sideRaw) ?? .both }
        set { sideRaw = newValue.rawValue }
    }
}

@Model
final class WaterIntake {
    @Attribute(.unique) var id: UUID
    /// Use startOfDay(for:) for daily grouping
    var date: Date
    var ounces: Double

    init(id: UUID = UUID(), date: Date, ounces: Double) {
        self.id = id
        self.date = date
        self.ounces = ounces
    }
}

@Model
final class DiaperEvent {
    @Attribute(.unique) var id: UUID
    var time: Date
    /// "wet", "dirty" or "both"
    var kind: String
    var mom: MomProfile?

    init(id: UUID = UUID(), time: Date = .now, kind: String, mom: MomProfile? = nil) {
        self.id = id
        self.time = time
        self.kind = kind
        self.mom = mom
    }
}

@Model
final class MilkSession {
    @Attribute(.unique) var id: UUID
    var startedAt: Date
    var endedAt: Date?
    /// "nurse" or "pump"
    var type: String
    // Persist side as simple string for schema stability
    var sideRaw: String?
    var mom: MomProfile?

    init(id: UUID = UUID(),
         startedAt: Date = .now,
         endedAt: Date? = nil,
         type: String,
         mom: MomProfile? = nil,
         sideRaw: String? = nil) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.type = type
        self.mom = mom
        self.sideRaw = sideRaw
    }

    // MARK: - Typed accessors
    enum Mode: String, Codable { case nurse, pump }
    enum Side: String, Codable, CaseIterable { case left, right }

    var mode: Mode {
        get { Mode(rawValue: type) ?? .nurse }
        set { type = newValue.rawValue }
    }

    var side: Side? {
        get { sideRaw.flatMap { Side(rawValue: $0) } }
        set { sideRaw = newValue?.rawValue }
    }

    var start: Date {
        get { startedAt }
        set { startedAt = newValue }
    }

    var end: Date? {
        get { endedAt }
        set { endedAt = newValue }
    }

    var durationSec: Int {
        max(0, Int((end ?? Date()).timeIntervalSince(start)))
    }

    convenience init(mom: MomProfile? = nil,
                     mode: Mode,
                     side: Side? = nil,
                     start: Date = .now,
                     end: Date? = nil) {
        self.init(startedAt: start,
                  endedAt: end,
                  type: mode.rawValue,
                  mom: mom,
                  sideRaw: side?.rawValue)
    }
}

@Model
final class WeightEntry {
    @Attribute(.unique) var id: UUID
    var date: Date
    var weightLb: Double

    init(id: UUID = UUID(), date: Date, weightLb: Double) {
        self.id = id
        self.date = date
        self.weightLb = weightLb
    }
}

@Model
final class MilkBag {
    @Attribute(.unique) var id: UUID
    var date: Date
    var ounces: Double

    init(id: UUID = UUID(), date: Date, ounces: Double) {
        self.id = id
        self.date = date
        self.ounces = ounces
    }
}

// MARK: - Diet calculator types (used by DietViews)

enum GoalPace: String {
    case maintain, lose025, lose05
}

struct CaloriePlan {
    let calories: Int
    let proteinG: Int
    let fatG: Int
    let carbsG: Int
}

/// Simple, stable coach calculator for daily calories & macros.
/// - Uses Mifflin-St Jeor (female), activity multiplier, breastfeeding add-on,
///   a gentle goal delta, and protein-forward macros.
enum CoachCalculator {
    static func dailyPlan(
        age: Int,
        heightCm: Double,
        weightLb: Double,
        activity: String,              // "sedentary", "light", "moderate"
        breastfeedingStatus: String,   // "exclusive", "partial", "weaning"
        calorieFloor: Int = 1800,
        goal: GoalPace = .maintain
    ) -> CaloriePlan {

        // metric
        let kg = max(30.0, weightLb * 0.45359237)
        let cm = heightCm

        // BMR (female)
        let bmr = 10*kg + 6.25*cm - 5*Double(age) - 161

        // activity multiplier
        let mult: Double = {
            switch activity.lowercased() {
            case "moderate": return 1.7
            case "light":    return 1.5
            default:         return 1.3 // sedentary/default
            }
        }()

        // breastfeeding energy add
        let bfAdd: Double = {
            switch breastfeedingStatus.lowercased() {
            case "exclusive": return 400
            case "partial":   return 250
            default:          return 0
            }
        }()

        var tdee = bmr * mult + bfAdd

        // goal adjustment
        let delta: Double = {
            switch goal {
            case .maintain: return 0
            case .lose025:  return -250
            case .lose05:   return -500
            }
        }()

        var calories = Int(max(Double(calorieFloor), tdee + delta).rounded())

        // macros
        let proteinG = Int((1.6 * kg).rounded())                // ~1.6 g/kg
        let fatG = Int((0.30 * Double(calories) / 9.0).rounded()) // ~30% fat
        let carbsG = max(0, Int(((Double(calories)
                                  - (Double(proteinG)*4 + Double(fatG)*9)) / 4).rounded()))

        // keep calories consistent with computed macros
        let recomputed = proteinG*4 + fatG*9 + carbsG*4
        calories = max(calories, recomputed)

        return CaloriePlan(calories: calories,
                           proteinG: proteinG,
                           fatG: fatG,
                           carbsG: carbsG)
    }
}
