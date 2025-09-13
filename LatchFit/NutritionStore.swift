import Foundation
import SwiftData

struct NutritionStore {
    let context: ModelContext
    let mom: MomProfile

    /// Find or create today's DayNutritionLog for the active mom
    func todayLog() throws -> DayNutritionLog {
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = #Predicate<DayNutritionLog> { log in
            log.mom?.id == mom.id && log.date == start
        }
        let descriptor = FetchDescriptor<DayNutritionLog>(predicate: predicate)
        if let existing = try context.fetch(descriptor).first {
            return existing
        }
        let log = DayNutritionLog(date: start, mom: mom)
        context.insert(log)
        try context.save()
        return log
    }

    /// Log a meal from a recipe, scaling nutrients by servings
    func logMeal(from recipe: RecipeIdea, servings: Double, when: Date = .now) throws {
        let perServing = Nutrients(
            calories: Double(recipe.perServing.cal),
            protein: Double(recipe.perServing.protein),
            carbs: 0, fat: 0, fiber: 0, sugar: 0, sodium: 0)
        try logMeal(from: perServing, quantity: servings, unit: "serving", when: when, food: nil)
    }

    /// Log a meal from an arbitrary Food item with known nutrients
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
