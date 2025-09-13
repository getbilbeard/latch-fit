import Foundation

protocol NutritionProvider {
    func searchFoods(query: String, page: Int) async throws -> [Food]
    func fetchDetails(fdcId: Int64) async throws -> (Food, [FoodPortion], Nutrients)
}

struct FoodDataCentralProvider: NutritionProvider {
    let apiKey: String
    let session: URLSession = .shared

    func searchFoods(query: String, page: Int = 1) async throws -> [Food] {
        var comps = URLComponents(string: "https://api.nal.usda.gov/fdc/v1/foods/search")!
        comps.queryItems = [
            .init(name: "api_key", value: apiKey),
            .init(name: "query", value: query),
            .init(name: "pageNumber", value: String(page))
        ]
        let (data, _) = try await session.data(from: comps.url!)
        let decoded = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let foods = (decoded?["foods"] as? [[String: Any]] ?? []).compactMap { item -> Food? in
            guard let description = item["description"] as? String, let fdcId = item["fdcId"] as? Int64 else { return nil }
            let brand = item["brandOwner"] as? String
            return Food(name: description, brand: brand, fdcId: fdcId)
        }
        return foods
    }

    func fetchDetails(fdcId: Int64) async throws -> (Food, [FoodPortion], Nutrients) {
        var comps = URLComponents(string: "https://api.nal.usda.gov/fdc/v1/food/\(fdcId)")!
        comps.queryItems = [.init(name: "api_key", value: apiKey)]
        let (data, _) = try await session.data(from: comps.url!)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let description = json?["description"] as? String ?? ""
        let brand = json?["brandOwner"] as? String
        let food = Food(name: description, brand: brand, fdcId: fdcId)
        let nutrientsArray = json?["labelNutrients"] as? [String: Any] ?? [:]
        let nutrients = Nutrients(
            calories: (nutrientsArray["calories"] as? [String: Any])?["value"] as? Double ?? 0,
            protein: (nutrientsArray["protein"] as? [String: Any])?["value"] as? Double ?? 0,
            carbs: (nutrientsArray["carbohydrates"] as? [String: Any])?["value"] as? Double ?? 0,
            fat: (nutrientsArray["fat"] as? [String: Any])?["value"] as? Double ?? 0,
            fiber: (nutrientsArray["fiber"] as? [String: Any])?["value"] as? Double ?? 0,
            sugar: (nutrientsArray["sugars"] as? [String: Any])?["value"] as? Double ?? 0,
            sodium: (nutrientsArray["sodium"] as? [String: Any])?["value"] as? Double ?? 0
        )
        let portions: [FoodPortion] = []
        return (food, portions, nutrients)
    }
}

struct LocalFoodProvider: NutritionProvider {
    let foods: [Food]
    let portionsMap: [UUID: [FoodPortion]]
    let nutrientsMap: [UUID: Nutrients]

    init() {
        let url = Bundle.main.url(forResource: "foods_min", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        let items = try! JSONDecoder().decode([LocalFoodItem].self, from: data)
        var f: [Food] = []
        var p: [UUID: [FoodPortion]] = [:]
        var n: [UUID: Nutrients] = [:]
        for item in items {
            let food = Food(name: item.name, brand: item.brand, fdcId: item.fdcId, portionType: item.portionType)
            f.append(food)
            p[food.id] = item.portions
            n[food.id] = item.nutrients
        }
        self.foods = f
        self.portionsMap = p
        self.nutrientsMap = n
    }

    func searchFoods(query: String, page: Int = 1) async throws -> [Food] {
        let lower = query.lowercased()
        return foods.filter { $0.name.lowercased().contains(lower) }
    }

    func fetchDetails(fdcId: Int64) async throws -> (Food, [FoodPortion], Nutrients) {
        throw NSError(domain: "LocalFoodProvider", code: 0, userInfo: [NSLocalizedDescriptionKey: "Not supported"])
    }

    func fetchDetails(foodId: UUID) -> (Food, [FoodPortion], Nutrients)? {
        guard let food = foods.first(where: { $0.id == foodId }), let portions = portionsMap[foodId], let nutrients = nutrientsMap[foodId] else { return nil }
        return (food, portions, nutrients)
    }

    private struct LocalFoodItem: Codable {
        var name: String
        var brand: String?
        var fdcId: Int64?
        var portionType: PortionType
        var nutrients: Nutrients
        var portions: [FoodPortion]
    }
}
