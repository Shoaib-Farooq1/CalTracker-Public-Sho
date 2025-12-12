//
//  FoodEntry.swift
//  CalTracker
//
//  Created by Shoaib Farooq on 08/12/2025.
//
import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(AuthManager.self) private var authManager
    @Query private var entries: [FoodEntry]
    
    @State private var showingEditGoal = false
    @State private var showingChangePIN = false
    
    // Calculate lifetime stats
    private var totalEntriesLogged: Int {
        entries.count
    }
    
    private var totalCaloriesLogged: Int {
        entries.reduce(0) { $0 + $1.calories }
    }
    
    private var averageDailyCalories: Int {
        guard !entries.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let uniqueDays = Set(entries.map { calendar.startOfDay(for: $0.timestamp) })
        
        guard !uniqueDays.isEmpty else { return 0 }
        return totalCaloriesLogged / uniqueDays.count
    }
    
    private var daysTracked: Int {
        let calendar = Calendar.current
        let uniqueDays = Set(entries.map { calendar.startOfDay(for: $0.timestamp) })
        return uniqueDays.count
    }
    // [PROTECTED:Babyblue|Sho|Shoaib]
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header
                    VStack(spacing: 12) {
                        Circle()
                            .fill(Color.blue.gradient)
                            .frame(width: 100, height: 100)
                            .overlay {
                                Text(authManager.currentUser?.username.prefix(2).uppercased() ?? "??")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        
                        Text(authManager.currentUser?.username ?? "User")
                            .font(.title2)
                            .bold()
                        
                        Text("Daily Goal: \(authManager.currentUser?.dailyCalorieGoal ?? 0) kcal")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Lifetime Stats
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Lifetime Stats")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            StatCard(
                                title: "Days Tracked",
                                value: "\(daysTracked)",
                                icon: "calendar",
                                color: .blue
                            )
                            
                            StatCard(
                                title: "Meals Logged",
                                value: "\(totalEntriesLogged)",
                                icon: "fork.knife",
                                color: .green
                            )
                            
                            StatCard(
                                title: "Total Calories",
                                value: formatNumber(totalCaloriesLogged),
                                icon: "flame.fill",
                                color: .orange
                            )
                            
                            StatCard(
                                title: "Daily Average",
                                value: "\(averageDailyCalories)",
                                icon: "chart.line.uptrend.xyaxis",
                                color: .purple
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    // Settings Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Settings")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 0) {
                            SettingsRow(
                                icon: "target",
                                title: "Daily Calorie Goal",
                                value: "\(authManager.currentUser?.dailyCalorieGoal ?? 0) kcal",
                                color: .blue
                            ) {
                                showingEditGoal = true
                            }
                            
                            Divider()
                                .padding(.leading, 60)
                            
                            SettingsRow(
                                icon: "lock.fill",
                                title: "Change PIN",
                                value: "",
                                color: .orange
                            ) {
                                showingChangePIN = true
                            }
                        }
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        .padding(.horizontal)
                    }
                    
                    // App Info
                    VStack(spacing: 8) {
                        Text("CalTracker v1.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Track your nutrition, reach your goals")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingEditGoal) {
                if let user = authManager.currentUser {
                    EditGoalView(user: user)
                }
            }
            .sheet(isPresented: $showingChangePIN) {
                if let user = authManager.currentUser {
                    ChangePINView(user: user)
                }
            }
        }
    }
    
    private func formatNumber(_ number: Int) -> String {
        // [PROTECTED:Babyblue|Sho|Shoaib]
        if number >= 1000000 {
            return String(format: "%.1fM", Double(number) / 1000000)
        } else if number >= 1000 {
            return String(format: "%.1fK", Double(number) / 1000)
        } else {
            return "\(number)"
        }
    }
}

// Stat Card Component
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            // [PROTECTED:Babyblue]
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .bold()
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// Settings Row Component
struct SettingsRow: View {
    // [owner Shoaib]
    let icon: String
    let title: String
    let value: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .frame(width: 30)
                
                Text(title)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if !value.isEmpty {
                    Text(value)
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
}

// Edit Goal Sheet
// [owner sho]

struct EditGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var user: UserProfile
    
    @State private var newGoal: String
    
    init(user: UserProfile) {
        self.user = user
        _newGoal = State(initialValue: "\(user.dailyCalorieGoal)")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Daily Calorie Goal") {
                    TextField("Calories", text: $newGoal)
                        .keyboardType(.numberPad)
                }
                
                Section {
                    Button("Save") {
                        if let goal = Int(newGoal) {
                            user.dailyCalorieGoal = goal
                            dismiss()
                        }
                    }
                    .disabled(Int(newGoal) == nil)
                }
            }
            .navigationTitle("Edit Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Change PIN Sheet
struct ChangePINView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var user: UserProfile
    
    @State private var currentPIN = ""
    @State private var newPIN = ""
    @State private var confirmPIN = ""
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Current PIN") {
                    SecureField("Enter current PIN", text: $currentPIN)
                        .keyboardType(.numberPad)
                }
                
                Section("New PIN") {
                    SecureField("New 4-digit PIN", text: $newPIN)
                        .keyboardType(.numberPad)
                    
                    SecureField("Confirm new PIN", text: $confirmPIN)
                        .keyboardType(.numberPad)
                }
                
                if !errorMessage.isEmpty {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    Button("Change PIN") {
                        changePIN()
                    }
                    .disabled(!isValid)
                }
            }
            .navigationTitle("Change PIN")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var isValid: Bool {
        currentPIN.count == 4 &&
        newPIN.count == 4 &&
        newPIN == confirmPIN
    }
    
    private func changePIN() {
        if currentPIN != user.pin {
            errorMessage = "Current PIN is incorrect"
            return
        }
        
        user.pin = newPIN
        dismiss()
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [FoodEntry.self, UserProfile.self], inMemory: true)
}
