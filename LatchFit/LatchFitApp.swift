import SwiftUI
import SwiftData
import Foundation

@main
struct LatchFitApp: App {

    // Runtime feature switches (make sure FeatureFlags.swift exists with this class)
    @StateObject private var flags = FeatureFlags()
    @StateObject private var activeProfileStore = ActiveProfileStore()

    #if DEBUG
    @State private var showDebugFlags = false
    #endif

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(flags)
                .environmentObject(activeProfileStore)
            #if DEBUG
                .modifier(DebugPanelTrigger(showSheet: $showDebugFlags))
                .sheet(isPresented: $showDebugFlags) {
                    DebugFlagsView()
                        .environmentObject(flags)
                }
            #endif
        }
        .modelContainer(sharedModelContainer) // Inject SwiftData once at the app root
    }
}

#if DEBUG
/// Invisible debug opener: triple-tap top-left OR long-press anywhere to open Debug Flags.
private struct DebugPanelTrigger: ViewModifier {
    @Binding var showSheet: Bool
    func body(content: Content) -> some View {
        content
            .overlay(
                Color.clear
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 3) { showSheet = true },
                alignment: .topLeading
            )
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 1.2)
                    .onEnded { _ in showSheet = true }
            )
    }
}
#endif

// MARK: - Shared SwiftData container
@MainActor
let sharedModelContainer: ModelContainer = {
    let schema = Schema([
        MomProfile.self,
        WeightEntry.self,
        PumpSession.self,
        DiaperEvent.self,   // Baby tab
        MilkBag.self,
        WaterIntake.self
    ])

    // Persistent on-disk store
    let storeURL = URL.documentsDirectory.appending(path: "LatchFit.store")
    let config = ModelConfiguration(url: storeURL)

    do {
        // Primary: open existing/on-disk schema
        let container = try ModelContainer(for: schema, configurations: [config])
        return container
    } catch {
        // If incompatible, wipe local store (DEV convenience). Ship real migration later.
        do {
            try? FileManager.default.removeItem(at: storeURL)
            let fresh = try ModelContainer(for: schema, configurations: [config])
            return fresh
        } catch {
            // Last-resort Debug fallback so the app still runs
            #if DEBUG
            let memoryConfig = ModelConfiguration(isStoredInMemoryOnly: true)
            let tmp = try! ModelContainer(for: schema, configurations: [memoryConfig])
            return tmp
            #else
            fatalError("Failed to create ModelContainer: \(error)")
            #endif
        }
    }
}()
