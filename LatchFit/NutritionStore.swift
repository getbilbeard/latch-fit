import Foundation
import SwiftData

struct NutritionStore {
    let context: ModelContext
    let mom: MomProfile

    func todayLog() throws -> DayNutritionLog {
        let start = Calendar.current.startOfDay(for: Date())
        // Fetch by date only (simple predicate), then filter mom in memory to dodge optional-keypath predicate issues
        let byDate = FetchDescriptor<DayNutritionLog>(
            predicate: #Predicate { $0.date == start }
        )
        if let existing = try context.fetch(byDate).first(where: { $0.mom?.id == mom.id }) {
            return existing
        }
        let created = DayNutritionLog(date: start, mom: mom)
        context.insert(created)
        try context.save()
        return created
    }

    func logMeal(from recipe: RecipeIdea, servings: Double, when: Date = .now) throws {
        let perServing = Nutrients(
            calories: Double(recipe.perServing.cal),
            protein: Double(recipe.perServing.protein),
            carbs: 0, fat: 0, fiber: 0, sugar: 0, sodium: 0
        )
        try logMeal(from: perServing, quantity: servings, unit: "serving", when: when, food: nil)
    }

    func logMeal(from food: Food, quantity: Double, unit: String, nutrients: Nutrients, when: Date = .now) throws {
        try logMeal(from: nutrients, quantity: quantity, unit: unit, when: when, food: food)
    }

    private func logMeal(from nutrients: Nutrients, quantity: Double, unit: String, when: Date, food: Food?) throws {
        let scaled = nutrients.scaled(by: quantity)
        let item = MealItem(date: when, food: food, mom: mom, quantity: quantity, unit: unit, nutrients: scaled)
        context.insert(item)

        let log = try todayLog()
        log.add(scaled)
        try context.save()
    }
}
