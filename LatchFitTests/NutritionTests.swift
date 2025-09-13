import Testing
@testable import LatchFit

struct NutritionTests {
    @Test func loadLocalFoods() async throws {
        let provider = LocalFoodProvider()
        let foods = try await provider.searchFoods(query: "banana", page: 1)
        #expect(!foods.isEmpty)
    }
}
