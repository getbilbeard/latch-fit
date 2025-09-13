import Foundation
import SwiftData

@Model
final class NutritionGoals {
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var fiber: Double
    var sugar: Double
    var sodium: Double

    init(calories: Double = 2000,
         protein: Double = 120,
         carbs: Double = 220,
         fat: Double = 70,
         fiber: Double = 25,
         sugar: Double = 30,
         sodium: Double = 2300) {
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
        self.sodium = sodium
    }
}

extension NutritionGoals {
    func remaining(vs totals: DayNutritionLog) -> Nutrients {
        Nutrients(
            calories: max(0, calories - totals.totalCalories),
            protein:  max(0, protein  - totals.totalProtein),
            carbs:    max(0, carbs    - totals.totalCarbs),
            fat:      max(0, fat      - totals.totalFat),
            fiber:    max(0, fiber    - totals.totalFiber),
            sugar:    max(0, sugar    - totals.totalSugar),
            sodium:   max(0, sodium   - totals.totalSodium)
        )
    }
}
