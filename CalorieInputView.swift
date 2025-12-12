//
//  FoodEntry.swift
//  CalTracker
//
//  Created by Shoaib Farooq on 08/12/2025.
//
import SwiftUI
import SwiftData
import PhotosUI
// [owner Shoaib]

struct CalorieInputView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var foodDescription: String = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var hasImage: Bool = false

    // Calculated results
    @State private var calculatedCalories: Int?
    @State private var calculatedProtein: Double?
    @State private var calculatedCarbs: Double?
    @State private var calculatedFats: Double?

    @State private var isCalculating = false
    private let apiService = OpenAIService()

    var body: some View {
        NavigationStack {
            Form {
                Section("Describe your food") {
                    TextField("e.g., 150g grilled chicken with 1 cup rice", text: $foodDescription, axis: .vertical)
                        .lineLimit(3...6)
                    // [owner Shoaib]

                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        HStack {
                            Image(systemName: hasImage ? "photo.fill.on.rectangle.fill" : "photo.on.rectangle")
                            Text(hasImage ? "Photo Selected" : "Select a Photo (optional)")
                        }
                    }
                    .onChange(of: selectedPhotoItem) { _, newValue in
                        hasImage = (newValue != nil)
                    }
                }

                Section {
                    Button(isCalculating ? "Calculating..." : "Calculate Calories") {
                        calculateCalories()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(foodDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isCalculating)
                }

                if calculatedCalories != nil || calculatedProtein != nil || calculatedCarbs != nil || calculatedFats != nil {
                    Section("Results") {
                        if let cals = calculatedCalories {
                            HStack {
                                Text("Calories")
                                Spacer()
                                Text("\(cals)")
                                // [owner Shoaib]
                 }
                        }
                        if let protein = calculatedProtein {
                            HStack {
                                Text("Protein")
                                Spacer()
                                Text(String(format: "%.1f g", protein))
                            }
                        }
                        if let carbs = calculatedCarbs {
                            HStack {
                                Text("Carbs")
                                Spacer()
                                Text(String(format: "%.1f g", carbs))
                            }
                        }
                        if let fats = calculatedFats {
                            HStack {
                                Text("Fats")
                                Spacer()
                                Text(String(format: "%.1f g", fats))
                            }
                        }

                        Button("Add to Log") {
                            // [owner Shoaib]
               addToLog()
                        }
                        .disabled(calculatedCalories == nil || calculatedProtein == nil || calculatedCarbs == nil || calculatedFats == nil)
                    }
                }
            }
            .navigationTitle("Add Food")
        }
    }

    private func calculateCalories() {
        print("🔴 BUTTON WAS CLICKED!")
        isCalculating = true
        print("🔍 Starting calculation for: \(foodDescription)")

        Task {
            do {
                print("🔵 About to call API...")
                let nutrition = try await apiService.analyzeFood(
                    description: foodDescription,
                    photoItem: selectedPhotoItem
                )
                print("✅ API returned: \(nutrition.calories) calories")

                await MainActor.run {
                    calculatedCalories = nutrition.calories
                    calculatedProtein = nutrition.protein
                    calculatedCarbs = nutrition.carbs
                    calculatedFats = nutrition.fats
                    isCalculating = false
                }
            } catch {
                await MainActor.run {
                    print("❌ ERROR: \(error)")
                    print("❌ ERROR DESCRIPTION: \(error.localizedDescription)")
                    isCalculating = false
                    
                    // Show error in UI with zeros
                    calculatedCalories = 0
                    calculatedProtein = 0
                    calculatedCarbs = 0
                    calculatedFats = 0
                }
            }
        }
    }

    private func addToLog() {
        guard let calories = calculatedCalories,
              let protein = calculatedProtein,
              let carbs = calculatedCarbs,
              let fats = calculatedFats else { return }
        // [owner Shoaib]

        let entry = FoodEntry(
            id: UUID(),
            timestamp: Date(),
            foodDescription: foodDescription,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fats: fats
        )

        modelContext.insert(entry)

        // Clear the form
        foodDescription = ""
        selectedPhotoItem = nil
        hasImage = false
        calculatedCalories = nil
        calculatedProtein = nil
        calculatedCarbs = nil
        calculatedFats = nil
    }
}

#Preview {
    CalorieInputView()
        .modelContainer(for: FoodEntry.self, inMemory: true)
}
