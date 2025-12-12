//
//  FoodEntry.swift
//  CalTracker
//
//  Created by Shoaib Farooq on 08/12/2025.
//
import Foundation
import SwiftData

@Observable
class AuthManager {
    var currentUser: UserProfile?
    var isAuthenticated: Bool {
        currentUser != nil
    }
    
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        print("🔧 AuthManager initialized")
    }
    
    func checkExistingUser() {
        print("🔍 Checking for existing user...")
        let descriptor = FetchDescriptor<UserProfile>()
        do {
            let users = try modelContext.fetch(descriptor)
            print("📊 Found \(users.count) users in database")
            if let user = users.first {
                currentUser = user
                print("✅ Existing user found: \(user.username)")
            } else {
                print("❌ No existing user found")
            }
        } catch {
            print("❌ Error fetching users: \(error)")
        }
    }
    
    func createAccount(username: String, pin: String, calorieGoal: Int) -> Bool {
        print("🔨 Creating account for: \(username)")
        
        // Check if user already exists
        let descriptor = FetchDescriptor<UserProfile>()
        do {
            let users = try modelContext.fetch(descriptor)
            print("📊 Current users in DB: \(users.count)")
            
            if !users.isEmpty {
                print("❌ User already exists, cannot create new account")
                return false
            }
            
            let newUser = UserProfile(username: username, pin: pin, dailyCalorieGoal: calorieGoal)
            modelContext.insert(newUser)
            
            // Force save
            try modelContext.save()
            print("✅ Account created and saved: \(username)")
            
            currentUser = newUser
            
            // Verify it was saved
            let verifyUsers = try modelContext.fetch(descriptor)
            print("🔍 Verification: \(verifyUsers.count) users after creation")
            
            return true
        } catch {
            print("❌ Error creating account: \(error)")
            return false
        }
    }
    
    func login(pin: String) -> Bool {
        print("🔑 Attempting login with PIN")
        let descriptor = FetchDescriptor<UserProfile>()
        do {
            let users = try modelContext.fetch(descriptor)
            print("📊 Found \(users.count) users for login")
            
            guard let user = users.first else {
                print("❌ No user found in database")
                return false
            }
            
            if user.pin == pin {
                currentUser = user
                print("✅ Login successful for: \(user.username)")
                return true
            } else {
                print("❌ Incorrect PIN")
                return false
            }
        } catch {
            print("❌ Error during login: \(error)")
            return false
        }
    }
    
    func logout() {
        print("👋 Logging out: \(currentUser?.username ?? "unknown")")
        currentUser = nil
    }
}
