import Foundation
import SwiftData

@Model
struct Food {
    @Attribute(.unique) var id: UUID
    var name: String
    var brand: String?
    var fdcId: Int64?
    var portionTypeRaw: String

    init(id: UUID = UUID(), name: String, brand: String? = nil, fdcId: Int64? = nil, portionType: PortionType = .per100g) {
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

    static var zero: Nutrients { .init(calories: 0, protein: 0, carbs: 0, fat: 0, fiber: 0, sugar: 0, sodium: 0) }
}

enum PortionType: String, Codable {
    case per100g
    case perServing
}

struct FoodPortion: Codable, Hashable {
    var grams: Double?
    var quantity: Double
    var unit: String
}

@Model
struct PantryItem {
    @Attribute(.unique) var id: UUID
    var food: Food
    var quantity: Double
    var unit: String
}

@Model
struct MealItem {
    @Attribute(.unique) var id: UUID
    var date: Date
    var food: Food
    var quantity: Double
    var unit: String
    var nutrients: Nutrients
}

@Model
struct DayNutritionLog {
    @Attribute(.unique) var id: UUID
    var date: Date
    var totals: Nutrients
}
