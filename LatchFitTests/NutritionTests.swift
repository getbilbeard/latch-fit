import Testing
@testable import LatchFit

struct NutritionTests {
    @Test func loadLocalFoods() async throws {
        let provider = LocalFoodProvider()
        let foods = try await provider.searchFoods(query: "banana", page: 1)
        #expect(!foods.isEmpty)
    }

    @Test func nutrientsScaled() throws {
        let original = Nutrients(calories: 100, protein: 10, carbs: 5, fat: 2, fiber: 1, sugar: 3, sodium: 4)
        let doubled = original.scaled(by: 2)
        #expect(doubled.calories == 200)
        #expect(doubled.protein == 20)
        #expect(doubled.carbs == 10)
    }
}
