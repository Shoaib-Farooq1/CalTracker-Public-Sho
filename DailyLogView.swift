//
//  FoodEntry.swift
//  CalTracker
//
//  Created by Shoaib Farooq on 08/12/2025.
//
import SwiftUI
import SwiftData

struct DailyLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var entries: [FoodEntry]
    
    @State private var editingEntry: FoodEntry?
    @State private var showingEditSheet = false
    
    // Computed totals for today
    private var todayEntries: [FoodEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return entries.filter { entry in
            calendar.isDate(entry.timestamp, inSameDayAs: today)
        }
    }
    
    private var totalCalories: Int {
        todayEntries.reduce(0) { $0 + $1.calories }
    }
    
    private var totalProtein: Double {
        todayEntries.reduce(0.0) { $0 + $1.protein }
    }
    
    private var totalCarbs: Double {
        todayEntries.reduce(0.0) { $0 + $1.carbs }
    }
    
    private var totalFats: Double {
        todayEntries.reduce(0.0) { $0 + $1.fats }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header - COMPACT VERSION
                HStack {
                    Image(systemName: "list.clipboard.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily Log")
                            .font(.headline)
                            .bold()
                        Text("Track your nutrition")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(Color.blue.opacity(0.1))
                
                // Daily totals card - COMPACT VERSION
                VStack(spacing: 8) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Today's Total")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(totalCalories) kcal")
                                .font(.title2)
                                .bold()
                        }
                        Spacer()
                    }
                    
                    HStack(spacing: 16) {
                        MacroView(label: "Protein", value: totalProtein, unit: "g")
                        MacroView(label: "Carbs", value: totalCarbs, unit: "g")
                        MacroView(label: "Fats", value: totalFats, unit: "g")
                    }
                    .font(.caption)
                }    // [owner Shoaib]

                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // List of entries
                if todayEntries.isEmpty {
                    Spacer()
                    Text("No food logged today")
                        .foregroundColor(.secondary)
                    Spacer()
                } else {
                    List {
                        ForEach(todayEntries) { entry in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(entry.foodDescription)
                                    .font(.headline)
                                
                                HStack {
                                    Text(entry.timestamp, style: .time)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Text("\(entry.calories) kcal")
                                        .font(.subheadline)
                                        .bold()
                                }
                                
                                HStack(spacing: 12) {
                                    MacroLabel(value: entry.protein, label: "P")
                                    MacroLabel(value: entry.carbs, label: "C")
                                    MacroLabel(value: entry.fats, label: "F")
                                }
                                .font(.caption)
                            }
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editingEntry = entry
                                showingEditSheet = true
                            }
                        }
                        .onDelete(perform: deleteEntries)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !todayEntries.isEmpty {
                    Button(role: .destructive) {
                        clearToday()
                    } label: {
                        Label("Clear Today", systemImage: "trash")
                    }
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                if let entry = editingEntry {
                    EditEntryView(entry: entry)
                }
            }
        }
    }
    
    private func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(todayEntries[index])
        }
    }
    
    private func clearToday() {
        for entry in todayEntries {
            modelContext.delete(entry)
        }
    }
}

// Edit sheet
struct EditEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var entry: FoodEntry
    
    @State private var editedCalories: String
    @State private var editedProtein: String
    @State private var editedCarbs: String
    @State private var editedFats: String
    
    init(entry: FoodEntry) {
        self.entry = entry
        _editedCalories = State(initialValue: "\(entry.calories)")
        _editedProtein = State(initialValue: String(format: "%.1f", entry.protein))
        _editedCarbs = State(initialValue: String(format: "%.1f", entry.carbs))
        _editedFats = State(initialValue: String(format: "%.1f", entry.fats))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Food") {
                    Text(entry.foodDescription)
                        .foregroundColor(.secondary)
                }
                
                Section("Edit Nutrition") {
                    HStack {
                        Text("Calories")
                        Spacer()
                        TextField("Calories", text: $editedCalories)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    HStack {
                        Text("Protein (g)")
                        Spacer()
                        TextField("Protein", text: $editedProtein)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    HStack {
                        Text("Carbs (g)")
                        Spacer()
                        TextField("Carbs", text: $editedCarbs)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    
                    HStack {
                        Text("Fats (g)")
                        Spacer()
                        TextField("Fats", text: $editedFats)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                }
            }
            .navigationTitle("Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveChanges() {
        if let calories = Int(editedCalories) {
            entry.calories = calories
        }
        if let protein = Double(editedProtein) {
            entry.protein = protein
        }
        if let carbs = Double(editedCarbs) {
            entry.carbs = carbs
        }
        if let fats = Double(editedFats) {
            entry.fats = fats
        }
    }
}

// Helper views for cleaner code
struct MacroView: View {
    let label: String
    let value: Double    // [owner Shoaib]
    let unit: String
    
    var body: some View {
        VStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text("\(value, specifier: "%.1f")\(unit)")
                .font(.subheadline)
                .bold()
        }
    }
}

struct MacroLabel: View {
    let value: Double
    let label: String
    // [owner Shoaib]

    var body: some View {
        Text("\(label): \(value, specifier: "%.1f")g")
            .foregroundColor(.secondary)
    }
}

#Preview {
    DailyLogView()    // [owner Shoaib]

        .modelContainer(for: FoodEntry.self, inMemory: true)
}
