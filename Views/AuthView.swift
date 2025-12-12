//
//  FoodEntry.swift
//  CalTracker
//
//  Created by Shoaib Farooq on 08/12/2025.
//
import SwiftUI
import SwiftData

struct AuthView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var authManager: AuthManager?
    @State private var hasExistingAccount = false
    
    var onAuthenticated: (AuthManager) -> Void
    
    var body: some View {
        NavigationStack {
            if hasExistingAccount {
                LoginView(authManager: authManager, onAuthenticated: onAuthenticated)
            } else {
                WelcomeView(authManager: authManager, onAuthenticated: onAuthenticated)
            }
        }
        .onAppear {
            initializeAuthManager()
            checkForAccount()
        }
    }
    
    private func initializeAuthManager() {
        if authManager == nil {
            authManager = AuthManager(modelContext: modelContext)
        }
    }
    
    private func checkForAccount() {
        let descriptor = FetchDescriptor<UserProfile>()
        if let users = try? modelContext.fetch(descriptor), !users.isEmpty {
            hasExistingAccount = true
        } else {
            hasExistingAccount = false
        }
    }
}

// Welcome screen for new users
struct WelcomeView: View {
    let authManager: AuthManager?
    let onAuthenticated: (AuthManager) -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Logo
            VStack(spacing: 10) {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("CalTracker")
                    .font(.largeTitle)
                    .bold()
                
                Text("Track your calories, build your goals")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Get started button
            NavigationLink {
                if let manager = authManager {
                    SignupView(authManager: manager, onAuthenticated: onAuthenticated)
                }
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .navigationBarHidden(true)
    }
}

// Login screen for existing users
struct LoginView: View {
    let authManager: AuthManager?
    let onAuthenticated: (AuthManager) -> Void
    
    @State private var pin = ""
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Logo
            VStack(spacing: 10) {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("CalTracker")
                    .font(.largeTitle)
                    .bold()
            }
            
            Spacer()
            
            // PIN entry
            VStack(spacing: 20) {
                Text("Enter your PIN")
                    .font(.headline)
                
                SecureField("4-digit PIN", text: $pin)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.center)
                    .font(.title2)
                    .frame(width: 200)
                    .onChange(of: pin) { oldValue, newValue in
                        if newValue.count == 4 {
                            attemptLogin()
                        }
                    }
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            Spacer()
        }
        .navigationBarHidden(true)
    }
    
    private func attemptLogin() {
        guard let manager = authManager else { return }
        
        if manager.login(pin: pin) {
            onAuthenticated(manager)
        } else {
            errorMessage = "Invalid PIN"
            pin = ""
        }
    }
}

// Signup screen
struct SignupView: View {
    let authManager: AuthManager
    let onAuthenticated: (AuthManager) -> Void
    
    @State private var username = ""
    @State private var pin = ""
    @State private var confirmPin = ""
    @State private var calorieGoal = "2000"
    @State private var errorMessage = ""
    
    var body: some View {
        Form {
            Section("Account Details") {
                TextField("Username", text: $username)
                
                SecureField("4-digit PIN", text: $pin)
                    .keyboardType(.numberPad)
                
                SecureField("Confirm PIN", text: $confirmPin)
                    .keyboardType(.numberPad)
            }
            
            Section("Daily Goal") {
                TextField("Daily Calorie Goal", text: $calorieGoal)
                    .keyboardType(.numberPad)
            }
            
            if !errorMessage.isEmpty {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }
            
            Section {
                Button("Create Account") {
                    createAccount()
                }
                .disabled(!isValid)
            }
        }
        .navigationTitle("Create Account")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private var isValid: Bool {
        !username.isEmpty &&
        pin.count == 4 &&
        pin == confirmPin &&
        Int(calorieGoal) != nil
    }
    
    private func createAccount() {
        guard let goal = Int(calorieGoal) else {
            errorMessage = "Invalid calorie goal"
            return
        }
        
        if authManager.createAccount(username: username, pin: pin, calorieGoal: goal) {
            onAuthenticated(authManager)
        } else {
            errorMessage = "Account already exists"
        }
    }
}
