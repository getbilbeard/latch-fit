import Foundation
import SwiftData

@Model
final class Food {
    @Attribute(.unique) var id: UUID
    var name: String
    var brand: String?
    var fdcId: Int64?
    var portionTypeRaw: String

    init(id: UUID = UUID(),
         name: String,
         brand: String? = nil,
         fdcId: Int64? = nil,
         portionType: PortionType = .per100g) {
        self.id = id
        self.name = name
        self.brand = brand
        self.fdcId = fdcId
        self.portionTypeRaw = portionType.rawValue
    }

    var portionType: PortionType {
        get { PortionType(rawValue: portionTypeRaw) ?? .per100g }
        set { portionTypeRaw = newValue.rawValue }
    }
}

struct Nutrients: Codable, Hashable {
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var fiber: Double
    var sugar: Double
    var sodium: Double

    static let zero = Nutrients(calories: 0, protein: 0, carbs: 0, fat: 0, fiber: 0, sugar: 0, sodium: 0)

    func scaled(by factor: Double) -> Nutrients {
        Nutrients(
            calories: calories * factor,
            protein:  protein  * factor,
            carbs:    carbs    * factor,
            fat:      fat      * factor,
            fiber:    fiber    * factor,
            sugar:    sugar    * factor,
            sodium:   sodium   * factor
        )
    }
}

enum PortionType: String, Codable { case per100g, perServing }

struct FoodPortion: Codable, Hashable {
    var grams: Double?
    var quantity: Double
    var unit: String
}

@Model
final class PantryItem {
    @Attribute(.unique) var id: UUID
    var food: Food
    var quantity: Double
    var unit: String

    init(id: UUID = UUID(), food: Food, quantity: Double, unit: String) {
        self.id = id
        self.food = food
        self.quantity = quantity
        self.unit = unit
    }
}

@Model
final class MealItem {
    @Attribute(.unique) var id: UUID
    var date: Date
    var food: Food?
    var mom: MomProfile?
    var quantity: Double
    var unit: String

    // Persist scalars (SwiftData doesn’t store custom structs well across versions)
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var fiber: Double
    var sugar: Double
    var sodium: Double

    init(id: UUID = UUID(),
         date: Date = .now,
         food: Food? = nil,
         mom: MomProfile? = nil,
         quantity: Double = 0,
         unit: String = "",
         nutrients: Nutrients = .zero) {
        self.id = id
        self.date = date
        self.food = food
        self.mom = mom
        self.quantity = quantity
        self.unit = unit
        self.calories = nutrients.calories
        self.protein = nutrients.protein
        self.carbs = nutrients.carbs
        self.fat = nutrients.fat
        self.fiber = nutrients.fiber
        self.sugar = nutrients.sugar
        self.sodium = nutrients.sodium
    }

    var nutrients: Nutrients {
        get { Nutrients(calories: calories, protein: protein, carbs: carbs, fat: fat, fiber: fiber, sugar: sugar, sodium: sodium) }
        set {
            calories = newValue.calories
            protein  = newValue.protein
            carbs    = newValue.carbs
            fat      = newValue.fat
            fiber    = newValue.fiber
            sugar    = newValue.sugar
            sodium   = newValue.sodium
        }
    }
}

@Model
final class DayNutritionLog {
    @Attribute(.unique) var id: UUID
    var date: Date
    var mom: MomProfile?

    var totalCalories: Double
    var totalProtein: Double
    var totalCarbs: Double
    var totalFat: Double
    var totalFiber: Double
    var totalSugar: Double
    var totalSodium: Double

    init(id: UUID = UUID(),
         date: Date = .now,
         mom: MomProfile? = nil,
         totals: Nutrients = .zero) {
        self.id = id
        self.date = date
        self.mom = mom
        self.totalCalories = totals.calories
        self.totalProtein  = totals.protein
        self.totalCarbs    = totals.carbs
        self.totalFat      = totals.fat
        self.totalFiber    = totals.fiber
        self.totalSugar    = totals.sugar
        self.totalSodium   = totals.sodium
    }

    var totals: Nutrients {
        get { Nutrients(calories: totalCalories, protein: totalProtein, carbs: totalCarbs, fat: totalFat, fiber: totalFiber, sugar: totalSugar, sodium: totalSodium) }
        set {
            totalCalories = newValue.calories
            totalProtein  = newValue.protein
            totalCarbs    = newValue.carbs
            totalFat      = newValue.fat
            totalFiber    = newValue.fiber
            totalSugar    = newValue.sugar
            totalSodium   = newValue.sodium
        }
    }

    func add(_ n: Nutrients) {
        totalCalories += n.calories
        totalProtein  += n.protein
        totalCarbs    += n.carbs
        totalFat      += n.fat
        totalFiber    += n.fiber
        totalSugar    += n.sugar
        totalSodium   += n.sodium
    }
}
