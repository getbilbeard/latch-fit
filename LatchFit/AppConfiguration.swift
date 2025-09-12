import Foundation

/// Describes the runtime environment for the app.
enum BuildEnvironment: String {
    case local, staging, production
}

/// Centralized configuration values for the application.
struct AppConfiguration {
    let environment: BuildEnvironment
    let recipeBackendBaseURL: URL?
    let enableAICoach: Bool
    let freeDailyRecipeQuota: Int
    let proDailyRecipeQuota: Int

    /// The configuration for the currently running build.
    static let current: AppConfiguration = {
        #if DEBUG
        // Toggle between .local and .staging during prelaunch
        return AppConfiguration(
            environment: .staging,
            recipeBackendBaseURL: URL(string: "https://latchfit-proxy.onrender.com"), // your Render/Vercel URL
            enableAICoach: true,
            freeDailyRecipeQuota: 5,
            proDailyRecipeQuota: 50
        )
        #else
        // App Store build
        return AppConfiguration(
            environment: .production,
            recipeBackendBaseURL: URL(string: "https://api.latchfit.app"),
            enableAICoach: true,
            freeDailyRecipeQuota: 5,
            proDailyRecipeQuota: 50
        )
        #endif
    }()
}

