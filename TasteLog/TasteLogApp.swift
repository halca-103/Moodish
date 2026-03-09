//
//  TasteLogApp.swift
//  TasteLog
//
//  Created by Fukushima Haruka on 2026/03/04.
//

//import SwiftUI
//
//@main
//struct tasteLogApp: App {
//    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
//
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//        }
//    }
//}

//import SwiftUI
//import SwiftData
//
//@main
//struct TasteLogApp: App {
//    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
//    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
//
//    var sharedModelContainer: ModelContainer = {
//        let schema = Schema([Recipe.self, CookingLog.self])
//        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
//        do {
//            return try ModelContainer(for: schema, configurations: [config])
//        } catch {
//            fatalError("ModelContainer作成失敗: \(error)")
//        }
//    }()
//
//    var body: some Scene {
//        WindowGroup {
//            if hasCompletedOnboarding {
//                ContentView()
//            } else {
//                OnboardingView()
//            }
//        }
//        .modelContainer(sharedModelContainer)
//    }
//}
import SwiftUI
import SwiftData

@main
struct TasteLogApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasSeededDefaultRecipes") private var hasSeededDefaultRecipes = false

    @State private var healthKit = HealthKitService()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Recipe.self, CookingLog.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("ModelContainer作成失敗: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if hasCompletedOnboarding {
                    ContentView()
                } else {
                    OnboardingView()
                }
            }
            .task {
                if !hasSeededDefaultRecipes {
                    try? DefaultRecipeSeeder.seedIfNeeded(in: sharedModelContainer.mainContext)
                    hasSeededDefaultRecipes = true
                }
                await healthKit.requestAuthorization()
            }
            .environment(healthKit)
        }
        .modelContainer(sharedModelContainer)
    }
}
