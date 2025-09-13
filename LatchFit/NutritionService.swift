import Foundation

@MainActor
class NutritionService {
    static let shared = NutritionService()

    private let provider: NutritionProvider

    init(provider: NutritionProvider? = nil) {
        if let provider = provider {
            self.provider = provider
        } else if let apiKey = ProcessInfo.processInfo.environment["FDC_API_KEY"], !apiKey.isEmpty {
            self.provider = FoodDataCentralProvider(apiKey: apiKey)
        } else {
            self.provider = LocalFoodProvider()
        }
    }

    func searchFoods(query: String, page: Int = 1) async -> [Food] {
        do {
            return try await provider.searchFoods(query: query, page: page)
        } catch {
            return []
        }
    }
}
