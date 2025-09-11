import Foundation

enum BuildEnvironment: String {
    case local, staging, production
}

struct AppConfiguration {
    let environment: BuildEnvironment
    let recipeBackendBaseURL: URL?
    let enableAICoach: Bool
    let freeDailyRecipeQuota: Int
    let proDailyRecipeQuota: Int

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
}//
//  AppConfiguration.swift
//  LatchFit
//
//  Created by Proxy on 9/10/25.
//

