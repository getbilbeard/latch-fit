import Foundation

// MARK: - Network model used by DietViews
// Keep this here (single source), and REMOVE any duplicate WebRecipe in other files.
public struct WebRecipe: Identifiable, Decodable {
    public struct Nutrition: Decodable {
        public struct Nutrient: Decodable { public let name: String; public let amount: Double; public let unit: String }
        public let nutrients: [Nutrient]
    }
    public let id: Int
    public let title: String
    public let image: String?
    public let servings: Int?
    public let readyInMinutes: Int?
    public let nutrition: Nutrition?
    // Optional convenience if your proxy flattens macros:
    public let calories: Double?
    public let proteinG: Double?
}

// MARK: - Protocol DietViews depends on
public protocol RecipeServing {
    func searchRecipes(
        ingredients: String,
        maxCalories: Int,
        minProtein: Int,
        count: Int
    ) async throws -> [WebRecipe]
}

// MARK: - Live service (call your proxy here)
public struct RecipeService: RecipeServing {
    public init() {}

    public func searchRecipes(
        ingredients: String,
        maxCalories: Int,
        minProtein: Int,
        count: Int
    ) async throws -> [WebRecipe] {
        // TODO: point to YOUR proxy (kept empty for now so prelaunch builds compile)
        // let base = URL(string: "https://api.yourdomain.com/recipes")!
        // var comps = URLComponents(url: base, resolvingAgainstBaseURL: false)!
        // comps.queryItems = [
        //     .init(name: "ingredients", value: ingredients),
        //     .init(name: "addRecipeNutrition", value: "true"),
        //     .init(name: "maxCalories", value: String(maxCalories)),
        //     .init(name: "minProtein",  value: String(minProtein)),
        //     .init(name: "number",      value: String(count))
        // ]
        // let (data, resp) = try await URLSession.shared.data(from: comps.url!)
        // guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
        //     throw URLError(.badServerResponse)
        // }
        // return try JSONDecoder().decode(RecipeSearchResponse.self, from: data).results

        // Prelaunch placeholder (no network yet):
        return []
    }
}

// MARK: - Mock service for quick testing / offline demos
public struct MockRecipeService: RecipeServing {
    public init() {}

    public func searchRecipes(
        ingredients: String,
        maxCalories: Int,
        minProtein: Int,
        count: Int
    ) async throws -> [WebRecipe] {
        // Very small, deterministic set that respects count.
        let seed: [WebRecipe] = [
            WebRecipe(
                id: 1,
                title: "Chicken & Rice Bowl",
                image: nil,
                servings: 2,
                readyInMinutes: 20,
                nutrition: WebRecipe.Nutrition(nutrients: [
                    .init(name: "Calories", amount: 520, unit: "kcal"),
                    .init(name: "Protein",  amount: 36,  unit: "g")
                ]),
                calories: 520, proteinG: 36
            ),
            WebRecipe(
                id: 2,
                title: "Tofu Veggie Stir-fry",
                image: nil,
                servings: 2,
                readyInMinutes: 18,
                nutrition: WebRecipe.Nutrition(nutrients: [
                    .init(name: "Calories", amount: 460, unit: "kcal"),
                    .init(name: "Protein",  amount: 28,  unit: "g")
                ]),
                calories: 460, proteinG: 28
            ),
            WebRecipe(
                id: 3,
                title: "Tuna Wraps",
                image: nil,
                servings: 1,
                readyInMinutes: 12,
                nutrition: WebRecipe.Nutrition(nutrients: [
                    .init(name: "Calories", amount: 430, unit: "kcal"),
                    .init(name: "Protein",  amount: 32,  unit: "g")
                ]),
                calories: 430, proteinG: 32
            )
        ]
        return Array(seed.prefix(max(1, min(count, seed.count))))
    }
}
