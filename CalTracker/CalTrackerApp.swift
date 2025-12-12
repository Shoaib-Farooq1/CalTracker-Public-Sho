//
//  FoodEntry.swift
//  CalTracker
//
//  Created by Shoaib Farooq on 08/12/2025.
//
import SwiftUI
import SwiftData

@main
struct CalTrackerApp: App {
    @State private var authManager: AuthManager?
    @State private var isAuthenticated = false
    
    let container: ModelContainer
    
    init() {
        print("🚀 App initializing...")
        do {
            container = try ModelContainer(for: FoodEntry.self, UserProfile.self)
            print("✅ ModelContainer created successfully")
        } catch {
            print("❌ Failed to create ModelContainer: \(error)")
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if isAuthenticated, let manager = authManager {
                    ContentView()
                        .environment(manager)
                } else {
                    AuthView { manager in
                        print("🎉 Authentication successful")
                        authManager = manager
                        isAuthenticated = true
                    }
                }
            }
            .modelContainer(container)
            .onAppear {
                print("🔄 App appeared, checking for existing user...")
                checkForExistingUser()
            }
        }
    }
    
    private func checkForExistingUser() {
        let context = container.mainContext
        let manager = AuthManager(modelContext: context)
        manager.checkExistingUser()
        
        print("🔍 Is authenticated after check: \(manager.isAuthenticated)")
        
        // Don't auto-login, just prepare the manager
        authManager = manager
    }
}
